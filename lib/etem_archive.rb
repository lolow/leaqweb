#--
# Copyright (c) 2009-2012, Public Research Center Henri Tudor
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'zip/zip'
require 'zip/zipfilesystem'
require 'zip_tools'

class EtemArchive
include ZipTools

  # Vide rapidement la base de données 
  def self.clean_database

    paper_trail_state  = PaperTrail.enabled?
    PaperTrail.enabled = false

    begin
      Technology.delete_all
      Commodity.delete_all
      Flow.delete_all
      Parameter.delete_all
      ParameterValue.delete_all
      TechnologySet.delete_all
      CommoditySet.delete_all
      Scenario.delete_all
      ActiveRecord::Base.connection.execute("DELETE FROM `commodities_flows`")
      ActiveRecord::Base.connection.execute("DELETE FROM `technology_sets_technologies`")
      ActiveRecord::Base.connection.execute("DELETE FROM `commodity_sets_commodities`")
    ensure
      PaperTrail.enabled = paper_trail_state
    end

    Version.delete_all
    Scenario.create(:name=>"BASE")

  end

  # Backup data in a zipped file containing csv files.
  #def self.backup(filename)
  #end

  # Restore data from a backup
  def self.restore(filename)

    paper_trail_state  = PaperTrail.enabled?
    PaperTrail.enabled = false

    begin

      #Hashes de correspondence
      h = Hash.new
      [:loc,:tec,:com,:flo,:par,:mkt, :agg].each { |x| h[x] = Hash.new  }

      ZipTools::readline_zip(filename,Technology) do |row|
        t = Technology.create!(:name        => row["name"],
                               :description => row["description"])
        t.set_list = row["sets"]
        t.save!
        h[:tec][row["id"]] = t.id
      end

      ZipTools::readline_zip(filename,Parameter) do |row|
        case row["type"]
        when "DemandDriver"
          param = DemandDriver.new
        else
          #param = Parameter.new
        end
        param.name = row["name"]
        param.definition = row["definition"]
        param.default_value = row["default_value"]
        param.save
        h[:par][row["id"]] = param.id
      end

      ZipTools::readline_zip(filename,Commodity) do |row|
        c = Commodity.create({:name              => row["name"],
                              :description       => row["description"],
                              :demand_driver_id  => h[:par][row["demand_driver_id"]],
                              :default_demand_elasticity => row["default_demand_elasticity"]},
                             :without_protection => true)
        c.set_list = row["sets"]
        c.save!
        h[:com][row["id"]] = c.id
      end

      ZipTools::readline_zip(filename,Flow) do |row|
        commodity_ids = row["commodities"].scan(/\d+/).collect{|c|h[:com][c]}
        attributes = { :technology_id => h[:tec][row["technology_id"]],
                       :commodity_ids => commodity_ids }
        case row["type"]
        when "InFlow"
          h[:flo][row["id"]]=InFlow.create(attributes,:without_protection => true).id
        when "OutFlow"
          h[:flo][row["id"]]=OutFlow.create(attributes,:without_protection => true).id
        end
      end

      ZipTools::readline_zip(filename,TechnologySet) do |row|
        technology_ids = row["technologies"].scan(/\d+/).collect{|c|h[:tec][c]}
        m = TechnologySet.create({:name            => row["name"],
                           :description     => row["description"],
                           :technology_ids  => technology_ids},
                          :without_protection => true)
        m.set_list = row["sets"]
        m.save!
        h[:mkt][row["id"]] = m.id
      end

      ZipTools::readline_zip(filename,CommoditySet) do |row|
        commodity_ids = row["commodities"].scan(/\d+/).collect{|c|h[:com][c]}
        a = CommoditySet.create({:name          => row["name"],
                              :description   => row["description"],
                              :commodity_ids => commodity_ids},
                             :without_protection => true)
        a.set_list = row["sets"]
        a.save!
        h[:agg][row["id"]] = a.id
      end

      #Default scenario
      h[:sce] = Hash.new(Scenario.where(:name=>"BASE").find(:first).id)
      ZipTools::readline_zip(filename,Scenario) do |row|
        unless row["name"]=="BASE"
          s = Scenario.create({:name => row["name"]},:without_protection => true)
          h[:sce][row["id"]] = s.id
        end
      end

      ZipTools::readline_zip(filename,ParameterValue) do |row|
        pv = ParameterValue.new
        pv.parameter_id  = Parameter.where(:name=>row["parameter_id"]).id
        pv.technology_id = h[:tec][row["technology_id"]]
        pv.commodity_id  = h[:com][row["commodity_id"]]
        pv.commodity_set_id  = h[:agg][row["commodity_set_id"]]
        pv.flow_id       = h[:flo][row["flow_id"]]
        pv.in_flow_id    = h[:flo][row["in_flow_id"]]
        pv.out_flow_id   = h[:flo][row["out_flow_id"]]
        pv.technology_set_id     = h[:mkt][row["technology_set_id"]]
        pv.technology_subset_id = h[:mkt][row["technology_subset_id"]]
        pv.scenario_id   = h[:sce][row["scenario_id"]]
        pv.time_slice    = row["time_slice"]
        pv.year          = row["year"]
        pv.value         = row["value"]
        pv.source        = row["source"]
        pv.save
      end

    ensure
      PaperTrail.enabled = paper_trail_state
    end

  end

end
