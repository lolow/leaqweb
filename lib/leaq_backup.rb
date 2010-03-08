require 'faster_csv'
require 'zip/zip'
require 'zip/zipfilesystem'

class LeaqBackup
  
  # Vide rapidement la base de données 
  def self.clean_database
    Technology.delete_all
    Commodity.delete_all
    Flow.delete_all
    Parameter.delete_all
    ParameterValue.delete_all
    Location.delete_all
    ActiveRecord::Base.connection.execute("DELETE FROM `commodities_flows`")
    ActiveRecord::Base.connection.execute("DELETE FROM `locations_technologies`")
  end

  # Import all data in a serie of csv files encapsulated from a zip file.
  # --
  # Must match with export
  def self.restore(filename)

    clean_database  

    #Hashes de correspondance
    localization = Hash.new
    technology   = Hash.new
    commodity    = Hash.new
    flow         = Hash.new
    parameter    = Hash.new
    
    #localization
    read_csv_from_zip(filename,"localization") do |row|
      localization[row[0]] = Localization.create(:name => row[1]).id  
    end

    #technology
    read_csv_from_zip(filename,"technology") do |row|
      ids = row[4].scan(/\d+/).collect{|l| localization[l]}
      t = Technology.create(:name => row[1],
                            :description => row[2],
                            :localization_ids => ids)
      unless row[3].blank?
        t.tag_list = row[3]
        t.save
      end
      technology[row[0]] = t.id
    end
    
    #commodity
    read_csv_from_zip(filename,"commodity") do |row|
      c = Commodity.create(:name => row[1])
      unless row[2].blank?
        c.tag_list = row[2]
        c.save
      end
      commodity[row[0]] = c.id
    end
    
    #flow
    read_csv_from_zip(filename,"flow") do |row|
      ids = row[3].scan(/\d+/).collect{|c| commodity[c]}
      case row[1]
      when 'ConsumedFlow'
        flow[row[0]] = ConsumedFlow.create(:technology_id => technology[row[2]],
                                           :commodity_ids => ids
                                          ).id
      when 'ProducedFlow'
        flow[row[0]] = ProducedFlow.create(:technology_id => technology[row[2]],
                                           :commodity_ids => ids
                                          ).id
      end                                
    end
    
    #parameter
    read_csv_from_zip(filename,"parameter") do |row|
      parameter[row[0]] = Parameter.create(:name => row[1],
                                           :description => row[2],
                                           :default_value => row[3]
                                           ).id
    end
    
    #parameter_value
    sql = <<-EOL
          INSERT INTO `parameter_values` (`parameter_id`, `technology_id`, 
          `commodity_id`, `flow_id`, `consumed_flow_id` , `produced_flow_id`,
          `localization_id`, `time_slice`,`year`,`value`,
          `created_at`, `updated_at`) VALUES 
          EOL
    values = []
    read_csv_from_zip(filename,"parameter_value") do |row|
      row = [parameter[row[0]],technology[row[1]],commodity[row[2]],
             flow[row[3]],flow[row[4]],flow[row[5]],localization[row[6]],
             row[7],row[8].to_i,row[9].to_f,now_sql,now_sql]
      row.collect!{|x| x = if x.nil? then "'NULL'" else "'#{x}'" end}
      values << "(#{row.join(',')})"
    end
    ActiveRecord::Base.connection.execute(sql + values.join(','))
    
  end
  
  # Export all data in a serie of csv files encapsulated into a zip file.
  # --
  # Must match with import
  def self.backup(filename)

    Zip::ZipOutputStream.open(filename) do |zipfile|

      #localization
      write_csv_into_zip(zipfile, "localization") do |csv| 
        Localization.find(:all).each do |l|
          csv << [l.id,l.name]
        end
      end
      
      #technology
      write_csv_into_zip(zipfile, "technology") do |csv|
        Technology.find(:all).each do |t|
          csv << [t.id,t.name,t.description,t.cached_tag_list,
                  t.localizations.map(&:id).join(" ")]
        end
      end
      
      #commodity
      write_csv_into_zip(zipfile, "commodity") do |csv|
        Commodity.find(:all).each do |c|
          csv << [c.id,c.name,c.cached_tag_list]
        end
      end
      
      #flow
      write_csv_into_zip(zipfile, "flow") do |csv|
        Flow.find(:all).each do |f|
          csv << [f.id,f.class,f.technology_id,f.commodities.map(&:id).join(" ")]
        end
      end
      
      #parameter
      write_csv_into_zip(zipfile, "parameter") do |csv|
        Parameter.find(:all).each do |p|
          csv << [p.id,p.name,p.description,p.default_value]
        end
      end
      
      #parameter_value
      write_csv_into_zip(zipfile, "parameter_value") do |csv|
        ParameterValue.find(:all).each do |p|
          csv << [p.parameter_id,p.technology_id,p.commodity_id,
                  p.flow_id,p.consumed_flow_id,p.produced_flow_id,
                  p.localization_id,p.time_slice,p.year,p.value]
        end
      end
    end

  end
  
  private
  
  def read_csv_from_zip(file, filename)
    Zip::ZipInputStream::open(file) { |zipfile|
      while (entry = zipfile.get_next_entry)
        if entry.name==filename 
          FasterCSV.parse(zipfile.read) {|row| yield row}
        end
      end
    }
  end
  
  def write_csv_into_zip(zipfile, filename)
    zipfile.put_next_entry(filename)
    zipfile.print(FasterCSV.generate {|csv| yield csv})
  end

end