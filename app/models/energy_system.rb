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

require 'zip_tools'

class EnergySystem < ActiveRecord::Base

  #Relations
  has_many :technologies,     dependent: :destroy
  has_many :commodities,      dependent: :destroy
  has_many :demand_drivers,   dependent: :destroy
  has_many :commodity_sets,   dependent: :destroy
  has_many :technology_sets,  dependent: :destroy
  has_many :parameter_values, dependent: :delete_all
  has_many :scenarios,        dependent: :destroy

  #Validations
  validates :name, presence: true, uniqueness: true

  def to_s
    self.name
  end

  def base_scenario
    self.scenarios.find_by_name("BASE")
  end

  # Erase all components
  def erase
    paper_trail_state  = PaperTrail.enabled?
    PaperTrail.enabled = false
    begin
      Technology.destroy_all(energy_system_id: self)
      Commodity.destroy_all(energy_system_id: self)
      DemandDriver.destroy_all(energy_system_id: self)
      CommoditySet.destroy_all(energy_system_id: self)
      TechnologySet.destroy_all(energy_system_id: self)
      Scenario.destroy_all(energy_system_id: self)
      ParameterValue.delete_all(energy_system_id: self)
    ensure
      PaperTrail.enabled = paper_trail_state
    end
  end

  # Initialization of the energy system
  def init
    Scenario.create(name: "BASE", energy_system_id: self)
    #TODO init value of parameter?
  end

  # Import a zipped file the description of a complete energy system (Existing energy system is erased)
  def import(filename)

    # Erase existing energy system
    self.erase

    # Initialise
    self.init

    paper_trail_state  = PaperTrail.enabled?
    PaperTrail.enabled = false

    begin

      #Hashes de correspondence
      h = Hash.new
      [:loc,:tec,:com,:flo,:dmd,:mkt,:agg].each { |x| h[x] = Hash.new  }

      ZipTools::readline_zip(filename,Technology) do |row|
        t = Technology.create(name:             row["name"],
                              description:      row["description"],
                              energy_system_id: self)
        t.set_list = row["sets"]
        t.save!
        h[:tec][row["id"]] = t.id
      end

      ZipTools::readline_zip(filename,DemandDriver) do |row|
        d = DemandDriver.new(name:             row["name"],
                             definition:       row["definition"],
                             default_value:    row["default_value"],
                             energy_system_id: self)
        d.save
        h[:dmd][row["id"]] = d.id
      end

      ZipTools::readline_zip(filename,DemandDriverValue) do |row|
        d = DemandDriverValue.new(demand_driver_id: h[:dmd][row["demand_driver_id"]],
                                  year:             row["year"],
                                  value:            row["value"],
                                  source:           row["source"])
        d.save
      end

      ZipTools::readline_zip(filename,Commodity) do |row|
        c = Commodity.create(name:                      row["name"],
                             description:               row["description"],
                             demand_driver_id:          h[:par][row["demand_driver_id"]],
                             default_demand_elasticity: row["default_demand_elasticity"],
                             energy_system_id:          self)
        c.set_list = row["sets"]
        c.save!
        h[:com][row["id"]] = c.id
      end

      ZipTools::readline_zip(filename,Flow) do |row|
        commodity_ids = row["commodities"].scan(/\d+/).collect{|c|h[:com][c]}
        attributes = { technology_id: h[:tec][row["technology_id"]],
                       commodity_ids: commodity_ids }
        case row["type"]
          when "InFlow"
            h[:flo][row["id"]] = InFlow.create(attributes).id
          when "OutFlow"
            h[:flo][row["id"]] = OutFlow.create(attributes).id
          else
            nil
        end
      end

      ZipTools::readline_zip(filename,TechnologySet) do |row|
        technology_ids = row["technologies"].scan(/\d+/).collect{|c|h[:tec][c]}
        m = TechnologySet.create(name:             row["name"],
                                 description:      row["description"],
                                 technology_ids:   technology_ids ,
                                 energy_system_id: self)
        m.set_list = row["sets"]
        m.save!
        h[:mkt][row["id"]] = m.id
      end

      ZipTools::readline_zip(filename,CommoditySet) do |row|
        commodity_ids = row["commodities"].scan(/\d+/).collect{|c|h[:com][c]}
        a = CommoditySet.create(name:          row["name"],
                                description:   row["description"],
                                commodity_ids: commodity_ids)
        a.set_list = row["sets"]
        a.save!
        h[:agg][row["id"]] = a.id
      end

      h[:sce] = Hash.new(base_scenarios.id)
      ZipTools::readline_zip(filename,Scenario) do |row|
        unless row["name"]=="BASE"
          s = Scenario.create(name: row["name"])
          h[:sce][row["id"]] = s.id
        end
      end

      ZipTools::readline_zip(filename,ParameterValue) do |row|
        pv = ParameterValue.new
        pv.parameter_id  = Parameter.where(name: row["parameter_name"]).id
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

  # Return a zipped file which contains the complete energy system
  def zip(filename,subset_ids=nil)

    Zip::ZipOutputStream.open(filename) do |zipfile|
      headers = %W(id name description sets)
      ZipTools::write_csv_into_zip(zipfile,Technology, headers, self.technologies) do |t,csv|
        csv << [t.id,t.name,t.description,t.set_list.join(',')]
      end
      headers = %W(id name description sets demand_driver_id default_demand_elasticity)
      ZipTools::write_csv_into_zip(zipfile,Commodity, headers, self.technologies) do |c,csv|
        csv << [c.id,c.name,c.description,c.set_list.join(','),c.demand_driver_id,c.default_demand_elasticity]
      end
      headers = %W(id type technology_id commodities)
      ZipTools::write_csv_into_zip(zipfile,Flow, headers, Flow.where(technology_id: e.technologies) ) do |f,csv|
        csv << [f.id,f.class,f.technology_id,f.commodity_ids.join(' ')]
      end
      headers = %W(id name description)
      ZipTools::write_csv_into_zip(zipfile, DemandDriver, headers, self.demand_drivers) do |p,csv|
        csv << p.attributes.values_at(*headers)
      end
      headers = %W(demand_driver_id year value source)
      ZipTools::write_csv_into_zip(zipfile, DemandDriverValue, headers, self.demand_drivers) do |p,csv|
        csv << p.attributes.values_at(*headers)
      end
      headers = %W(parameter_name technology_id commodity_id commodity_set_id flow_id in_flow_id out_flow_id technology_set_id technology_subset_id time_slice year value source scenario_id)
      ZipTools::write_csv_into_zip(zipfile, ParameterValue, headers, self.parameter_values) do |pv,csv|
        csv << [pv.parameter.name,pv.technology_id,pv.commodity,pv.commodity_set,pv.flow_id,
                pv.in_flow_id,pv.out_flow_id,pv.technology_set_id,pv.technology_subset_id,pv.time_slice,
                pv.year,pv.value,pv.source,pv.scenario_id]
        pv.attributes.values_at(*headers)
      end
      headers = %W(id name description technologies sets)
      ZipTools::write_csv_into_zip(zipfile, TechnologySet, headers, self.technology_sets) do |m,csv|
        csv << [m.id,m.name,m.description,m.technology_ids.join(' '),m.set_list.join(',')]
      end
      headers = %W(id name description commodities sets)
      ZipTools::write_csv_into_zip(zipfile, CommoditySet, headers, self.commodity_sets) do |a,csv|
        csv << [a.id,a.name,a.description,a.commodity_ids.join(' '),a.set_list.join(',')]
      end
      headers = %W(id name)
      ZipTools::write_csv_into_zip(zipfile, Scenario, headers, self.scenarios) do |a,csv|
        csv << [a.id,a.name]
      end
    end

  end

end