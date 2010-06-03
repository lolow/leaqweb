require 'faster_csv'
require 'zip/zip'
require 'zip/zipfilesystem'

class LeaqArchive
  
  # Vide rapidement la base de données 
  def self.clean_database
    Technology.delete_all
    Commodity.delete_all
    Flow.delete_all
    Parameter.delete_all
    ParameterValue.delete_all
    Location.delete_all
    Table.delete_all
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
      loc[row[0]] = Location.create!(:name => row[1].chomp.sub(" ","_")).id
    }


    #technology
    readline_zip(Technology,zipfile,"technology.csv") do |row|
      ids = row[4].scan(/\d+/).collect{|l| loc[l]}
      t = Technology.create!(:name => row[1].chomp.sub(" ","_"),
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
      c = Commodity.create!(:name => row[1].chomp.sub(" ","_"),
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
                                        :default_value => row[3]
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
  
  # Backup data in a zipped file containing csv files.
  def self.backup(filename)

    def self.write_csv_into_zip(zipfile, active_record, headers)
      require 'benchmark'
      puts "-- #{active_record.name}"
      time = Benchmark.measure {
        zipfile.put_next_entry(active_record.name)
        zipfile.print(FasterCSV.generate do |csv|
          csv << headers
          active_record.all.each {|o| yield(o,csv)}
        end)
      }
      puts "   -> %.4fs" % time.real
    end

    Zip::ZipOutputStream.open(filename) do |zipfile|

      headers = ["id","name"]
      write_csv_into_zip(zipfile, Location, headers ) do |l,csv|
        csv << l.attributes.values_at(*headers)
      end

      headers = ["id","name","description","sets","locations"]
      write_csv_into_zip(zipfile, Technology, headers) do |t,csv|
        csv << [t.id,t.name,t.description,t.set_list.join(','),
               t.location_ids.join(' ')]
      end

      headers = ["id","name","description","sets","demand_driver_id","demand_elasticity"]
      write_csv_into_zip(zipfile, Commodity, headers) do |c,csv|
        csv << [c.id,c.name,c.description,c.set_list.join(','),c.demand_driver,c.demand_elasticity]
      end

      headers = ["id","type","technology_id","commodities"]
      write_csv_into_zip(zipfile, Flow, headers) do |f,csv|
        csv << [f.id,f.class,f.technology_id,f.commodity_ids.join(' ')]
      end

      headers = ["id","type","name","definition","default_value"]
      write_csv_into_zip(zipfile, Parameter,headers) do |p,csv|
        csv << p.attributes.values_at(*headers)
      end

      headers = ["parameter_id","technology_id","commodity_id","flow_id",
                 "in_flow_id","out_flow_id","location_id","time_slice",
                 "year","value","source"]
      write_csv_into_zip(zipfile, ParameterValue,headers) do |pv,csv|
        csv << pv.attributes.values_at(*headers)
      end

      headers = ["name","aggregate","variable","rows","columns","filters"]
      write_csv_into_zip(zipfile, Table,headers) do |pv,csv|
        csv << pv.attributes.values_at(*headers)
      end
    end

  end

  # Restore data from a backup
  def self.restore(filename)
    #Warning
    if [Technology,Commodity,Flow,Location,Parameter,ParameterValue].map(&:count).sum>0
      puts "Database not empty! Do you want to continue? (y/N)"
      return unless gets.chomp.upcase == "Y"
    end

    #Hashes de correspondance
    h = Hash.new
    [:loc,:tec,:com,:flo,:par].each { |x| h[x] = Hash.new  }

    def self.readline_zip(zipfile,active_record)
      require 'benchmark'
      puts "-- #{active_record.name}"
      time = Benchmark.measure {
        active_record.transaction {
          Zip::ZipInputStream::open(zipfile) { |file|
          while (entry = file.get_next_entry)
            if entry.name==active_record.name
              FasterCSV.parse(file.read,{:headers=>true}) {|row| yield row}
            end
          end
          }
        }
      }
      puts "   -> %.4fs" % time.real
    end
    
    readline_zip(filename,Location) do |row|
      h[:loc][row["id"]] = Location.create!(:name => row["name"]).id
    end

    readline_zip(filename,Technology) do |row|
      location_ids = row["locations"].scan(/\d+/).collect{|id|h[:loc][id]}
      t = Technology.create!(:name => row["name"],
                      :description => row["description"],
                     :location_ids => location_ids)
      t.set_list = row["sets"]
      t.save
      h[:tec][row["id"]] = t.id
    end

    readline_zip(filename,Parameter) do |row|
      case row["type"]
      when "DemandDriver"
        param = DemandDriver.new
      else
        param = Parameter.new
      end
      param.name = row["name"]
      param.definition = row["definition"]
      param.default_value = row["default_value"]
      param.save!
      h[:par][row["id"]] = param.id
    end

    readline_zip(filename,Commodity) do |row|
      c = Commodity.create!(:name => row["name"],
                     :description => row["description"],
                     :demand_driver_id => h[:par][row["demand_driver_id"]],
                     :demand_elasticity => row["demand_elasticity"])
      c.set_list = row["sets"]
      c.save
      h[:com][row["id"]] = c.id
    end

    readline_zip(filename,Flow) do |row|
      commodity_ids = row["commodities"].scan(/\d+/).collect{|c|h[:com][c]}
      attributes = { :technology_id => h[:tec][row["technology_id"]],
                     :commodity_ids => commodity_ids }
      case row["type"]
      when "InFlow"
        h[:flo][row["id"]]=InFlow.create!(attributes).id
      when "OutFlow"
        h[:flo][row["id"]]=OutFlow.create!(attributes).id
      end
    end

    readline_zip(filename,ParameterValue) do |row|
      pv = ParameterValue.new
      pv.parameter_id  = h[:par][row["parameter_id"]]
      pv.technology_id = h[:tec][row["technology_id"]]
      pv.commodity_id  = h[:com][row["commodity_id"]]
      pv.flow_id       = h[:flo][row["flow_id"]]
      pv.in_flow_id    = h[:flo][row["in_flow_id"]]
      pv.out_flow_id   = h[:flo][row["out_flow_id"]]
      pv.location_id   = h[:loc][row["location_id"]]
      pv.time_slice    = row["time_slice"]
      pv.year          = row["year"]
      pv.value         = row["value"]
      pv.source        = row["source"]
      pv.save
    end

    readline_zip(filename,Table) do |row|
      pv = Table.create!( :name => row["name"],
                          :aggregate => row["aggregate"],
                          :variable => row["variable"],
                          :rows => row["rows"],
                          :columns => row["columns"],
                          :filters => row["filters"] )
    end
    
  end

end