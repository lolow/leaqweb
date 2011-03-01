require 'csv'
require 'zip/zip'
require 'zip/zipfilesystem'

class EtemArchive
  
  # Vide rapidement la base de données 
  def self.clean_database
    Technology.delete_all
    Commodity.delete_all
    Flow.delete_all
    Parameter.delete_all
    ParameterValue.delete_all
    Market.delete_all
    Aggregate.delete_all
    StoredQuery.delete_all
    Combustion.delete_all
    ActiveRecord::Base.connection.execute("DELETE FROM `commodities_flows`")
    ActiveRecord::Base.connection.execute("DELETE FROM `markets_technologies`")
    ActiveRecord::Base.connection.execute("DELETE FROM `aggregates_commodities`")
  end

  # Backup data in a zipped file containing csv files.
  def self.backup(filename)

    def self.write_csv_into_zip(zipfile, active_record, headers)
      require 'benchmark'
      puts "-- #{active_record.name}"
      time = Benchmark.measure {
        zipfile.put_next_entry(active_record.name)
        text = CSV.generate do |csv|
          csv << headers
          active_record.all.each {|o| yield(o,csv)}
        end
        # zipfile.print(text) is buggy in ruby 1.9
        # the following line replaces it
        zipfile << text << $\.to_s
      }
      puts "   -> %.4fs" % time.real
    end

    Zip::ZipOutputStream.open(filename) do |zipfile|

      headers = ["id","name","description","sets"]
      write_csv_into_zip(zipfile,Technology, headers) do |t,csv|
        csv << [t.id,t.name,t.description,t.set_list.join(',')]
      end

      headers = ["id","name","description","sets","demand_driver_id","demand_elasticity"]
      write_csv_into_zip(zipfile,Commodity, headers) do |c,csv|
        csv << [c.id,c.name,c.description,c.set_list.join(','),c.demand_driver_id,c.demand_elasticity]
      end

      headers = ["id","type","technology_id","commodities"]
      write_csv_into_zip(zipfile,Flow, headers) do |f,csv|
        csv << [f.id,f.class,f.technology_id,f.commodity_ids.join(' ')]
      end

      headers = ["id","type","name","definition","default_value"]
      write_csv_into_zip(zipfile,Parameter,headers) do |p,csv|
        csv << p.attributes.values_at(*headers)
      end

      headers = ["parameter_id","technology_id","commodity_id","aggregate_id","flow_id",
                 "in_flow_id","out_flow_id","market_id","time_slice",
                 "year","value","source"]
      write_csv_into_zip(zipfile,ParameterValue,headers) do |pv,csv|
        csv << pv.attributes.values_at(*headers)
      end

      headers = ["name","aggregate","variable","rows","columns","filters"]
      write_csv_into_zip(zipfile,StoredQuery,headers) do |pv,csv|
        csv << pv.attributes.values_at(*headers)
      end
      
      headers = ["fuel_id","pollutant_id","value","source"]
      write_csv_into_zip(zipfile,Combustion,headers) do |pv,csv|
        csv << pv.attributes.values_at(*headers)
      end

      headers = ["id","name","description","technologies","sets"]
      write_csv_into_zip(zipfile,Market,headers) do |m,csv|
        csv << [m.id,m.name,m.description,m.technology_ids.join(' '),m.set_list.join(',')]
      end

      headers = ["id","name","description","commodities","sets"]
      write_csv_into_zip(zipfile,Aggregate,headers) do |a,csv|
        csv << [a.id,a.name,a.description,a.commodity_ids.join(' '),a.set_list.join(',')]
      end
      
    end

  end

  # Restore data from a backup
  def self.restore(filename)

    #Hashes de correspondance
    h = Hash.new
    [:loc,:tec,:com,:flo,:par,:mkt, :agg].each { |x| h[x] = Hash.new  }

    def self.readline_zip(zipfile,active_record)
      require 'benchmark'
      puts "-- #{active_record.name}"
      time = Benchmark.measure {
        active_record.transaction {
          Zip::ZipInputStream::open(zipfile) { |file|
          while (entry = file.get_next_entry)
            if entry.name==active_record.name
              CSV.parse(file.read,{:headers=>true}) {|row| yield row}
            end
          end
          }
        }
      }
      puts "   -> %.4fs" % time.real
    end

    readline_zip(filename,Technology) do |row|
      t = Technology.create!(:name        => row["name"],
                             :description => row["description"])
      t.set_list = row["sets"]
      t.save!
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
      c = Commodity.create!(:name              => row["name"],
                            :description       => row["description"],
                            :demand_driver_id  => h[:par][row["demand_driver_id"]],
                            :demand_elasticity => row["demand_elasticity"])
      c.set_list = row["sets"]
      c.save!
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

    readline_zip(filename,Market) do |row|
      technology_ids = row["technologies"].scan(/\d+/).collect{|c|h[:tec][c]}
      m = Market.create!(:name            => row["name"],
                         :description     => row["description"],
                         :technology_ids  => technology_ids)
      m.set_list = row["sets"]
      m.save!
      h[:mkt][row["id"]] = m.id
    end

    readline_zip(filename,Aggregate) do |row|
      commodity_ids = row["commodities"].scan(/\d+/).collect{|c|h[:com][c]}
      a = Aggregate.create!(:name          => row["name"],
                            :description   => row["description"],
                            :commodity_ids => commodity_ids)
      a.set_list = row["sets"]
      a.save!
      h[:agg][row["id"]] = a.id
    end

    readline_zip(filename,StoredQuery) do |row|
      StoredQuery.create!(:name      => row["name"],
                          :aggregate => row["aggregate"],
                          :variable  => row["variable"],
                          :rows      => row["rows"],
                          :columns   => row["columns"],
                          :filters   => row["filters"])
    end

    readline_zip(filename,Combustion) do |row|
      c = Combustion.create!(:fuel_id      => h[:com][row["fuel_id"]],
                             :pollutant_id => h[:com][row["pollutant_id"]],
                             :value        => row["value"],
                             :source       => row["source"])
    end

    readline_zip(filename,ParameterValue) do |row|
      pv = ParameterValue.new
      pv.parameter_id  = h[:par][row["parameter_id"]]
      pv.technology_id = h[:tec][row["technology_id"]]
      pv.commodity_id  = h[:com][row["commodity_id"]]
      pv.aggregate_id  = h[:agg][row["aggregate_id"]]
      pv.flow_id       = h[:flo][row["flow_id"]]
      pv.in_flow_id    = h[:flo][row["in_flow_id"]]
      pv.out_flow_id   = h[:flo][row["out_flow_id"]]
      pv.market_id     = h[:mkt][row["market_id"]]
      pv.time_slice    = row["time_slice"]
      pv.year          = row["year"]
      pv.value         = row["value"]
      pv.source        = row["source"]
      pv.save!
    end

  end

end