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
  def self.restore_db_python(zipfile)

    s = [Technology,Commodity,Flow,Location,Parameter,ParameterValue].map(&:count).sum
    if s>0
      puts "Database not empty! Do you want to continue? (y/N)"
      res = gets
      return unless res.chomp.upcase == "Y"
    end

    #Hashes de correspondance
    loc    = Hash.new
    tech   = Hash.new
    comm   = Hash.new
    flow   = Hash.new
    param  = Hash.new

    def self.readline_zip(active_record,zipfile,fname)
      require 'benchmark'
      puts "-- #{active_record.name}"
      time = Benchmark.measure {
        active_record.transaction {
          Zip::ZipInputStream::open(zipfile) { |file|
          while (entry = file.get_next_entry)
            FasterCSV.parse(file.read) {|row| yield row} if entry.name==fname
          end
          }
        }
      }
      puts "   -> %.4fs" % time.real
    end

    #location
    readline_zip(Location,zipfile,"geom.csv") { |row|
      loc[row[0]] = Location.create!(:name => row[1]).id
    }


    #technology
    readline_zip(Technology,zipfile,"technology.csv") do |row|
      ids = row[4].scan(/\d+/).collect{|l| loc[l]}
      t = Technology.create(:name => row[1],
                            :description => row[2],
                            :location_ids => ids)
      unless row[3].blank?
        t.set_list = row[3]
        t.save
      end
      tech[row[0]] = t.id
    end


    #commodity
    readline_zip(Commodity,zipfile,"commodity.csv") do |row|
      c = Commodity.create!(:name => row[1],
                            :description => row[2])
      unless row[3].blank?
        c.set_list = row[3]
        c.save
      end
      comm[row[0]] = c.id
    end
    
    #inflow
    readline_zip(InFlow,zipfile,"inflow.csv") do |row|
      ids = row[2].scan(/\d+/).collect{|c| comm[c]}
      flow[row[0]] = InFlow.create!(:technology_id => tech[row[1]],
                                    :commodity_ids => ids
                                    ).id
    end

    readline_zip(OutFlow,zipfile,"outflow.csv") do |row|
      ids = row[2].scan(/\d+/).collect{|c| comm[c]}
      flow[row[0]] = OutFlow.create!(:technology_id => tech[row[1]],
                                     :commodity_ids => ids
                                     ).id
    end
    
    #parameter
    readline_zip(Parameter,zipfile,"param.csv") do |row|
      param[row[0]] = Parameter.create!(:name => row[1],
                                        :definition => row[2],
                                        :default_value => row[3],
                                        :units => row[4]
                                        ).id
    end
    
    #parameter_value
    readline_zip(ParameterValue,zipfile,"paramvalue.csv") do |row|
      pv = ParameterValue.new
      pv.parameter_id  = param[row[0]]
      pv.technology_id = tech[row[1]] unless row[1]=="None"
      pv.commodity_id  = comm[row[2]] unless row[2]=="None"
      pv.flow_id       = flow[row[3]] unless row[3]=="None"
      pv.in_flow_id    = flow[row[4]] unless row[4]=="None"
      pv.out_flow_id   = flow[row[5]] unless row[5]=="None"
      pv.location_id   = loc[row[6]]  unless row[6]=="None"
      pv.time_slice    = row[7] unless row[7]=="None"
      pv.year          = row[8] unless row[8]=="None"
      pv.value         = row[9].to_f
      pv.source        = row[10] unless row[10]=="None"
      pv.save
    end
    
  end
  
  # Export all data in a serie of csv files encapsulated into a zip file.
  # --
  # Must match with import
  def self.backup(filename)

    def self.write_csv_into_zip(zipfile, filename)
      zipfile.put_next_entry(filename)
      zipfile.print(FasterCSV.generate {|csv| yield csv})
    end

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

end