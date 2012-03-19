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

  after_create :setup

  #Relations
  has_many :technologies,     dependent: :destroy
  has_many :commodities,      dependent: :destroy
  has_many :demand_drivers,   dependent: :destroy
  has_many :commodity_sets,   dependent: :destroy
  has_many :technology_sets,  dependent: :destroy
  has_many :parameter_values, dependent: :delete_all
  has_many :scenarios,        dependent: :destroy
  has_many :solver_jobs,      dependent: :destroy

  #Validations
  validates                 :name, presence: true, uniqueness: true
  validates_numericality_of :nb_periods, :greater_than_or_equal_to => 1, :only_integer => true
  validates_numericality_of :period_duration, :greater_than_or_equal_to => 1, :only_integer => true
  validates_numericality_of :first_year, :greater_than_or_equal_to => 1, :only_integer => true

  def to_s
    self.name
  end

  def last_year
    first_year - 1 + (nb_periods * period_duration)
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

  # Import a zipped file the description of a complete energy system (Existing energy system is erased)
  def import(filename)

    # Erase existing energy system
    self.erase

    paper_trail_state  = PaperTrail.enabled?
    PaperTrail.enabled = false

    begin

      #Hashes de correspondence
      h = Hash.new
      [:loc,:tec,:com,:flo,:dmd,:mkt,:agg, :par].each { |x| h[x] = Hash.new  }

      ZipTools::readline_zip(filename,EnergySystem) do |row|
        #self.name            = row["name"]
        self.description     = row["description"]
        self.first_year      = row["first_year"]
        self.nb_periods      = row["nb_periods"]
        self.period_duration = row["period_duration"]
        self.save
      end

      ZipTools::readline_zip(filename,Technology) do |row|
        t = Technology.create(name:           row["name"],
                              description:    row["description"],
                              energy_system: self)
        t.set_list = row["sets"]
        t.save
        h[:tec][row["id"]] = t.id
      end

      ZipTools::readline_zip(filename,DemandDriver) do |row|
        d = DemandDriver.new(name:          row["name"],
                             description:   row["definition"],
                             energy_system: self)
        d.save
        h[:dmd][row["id"]] = d.id
      end

      ZipTools::readline_zip(filename,Commodity) do |row|
        c = Commodity.create(name:                      row["name"],
                             description:               row["description"],
                             demand_driver_id:          h[:dmd][row["demand_driver_id"]],
                             projection_base_year:      row["projection_base_year"],
                             default_demand_elasticity: row["default_demand_elasticity"],
                             energy_system:             self)
        c.set_list = row["sets"]
        c.save
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
        m = TechnologySet.create(name:           row["name"],
                                 description:    row["description"],
                                 technology_ids: technology_ids ,
                                 energy_system:  self)
        m.set_list = "MARKET"
        m.save
        h[:mkt][row["id"]] = m.id
        h[:mkt2][row["id"]] = m.name
      end

      ZipTools::readline_zip(filename,CommoditySet) do |row|
        commodity_ids = row["commodities"].scan(/\d+/).collect{|c|h[:com][c]}
        a = CommoditySet.create(name:          row["name"],
                                description:   row["description"],
                                commodity_ids: commodity_ids,
                                energy_system: self)
        a.set_list = "AGG"
        a.save
        h[:agg][row["id"]] = a.id
        h[:agg2][row["id"]] = a.name
      end

      s = Scenario.create(name: "BASE", energy_system: self)
      h[:sce] = Hash.new(s.id)
      ZipTools::readline_zip(filename,Scenario) do |row|
        unless row["name"]=="BASE"
          s = Scenario.create(name: row["name"], energy_system: self)
          h[:sce][row["id"]] = s.id
        end
      end

      params = Parameter.all
      params.each{|p| h[:par][p.name] = p.id}
      ZipTools::readline_zip(filename,ParameterValue) do |row|
        pv = ParameterValue.new
        pv.parameter_id         = h[:par][row["parameter_name"]]
        pv.technology_id        = h[:tec][row["technology_id"]]
        pv.commodity_id         = h[:com][row["commodity_id"]]
        pv.commodity_set_id     = h[:agg][row["commodity_set_id"]]
        pv.flow_id              = h[:flo][row["flow_id"]]
        pv.in_flow_id           = h[:flo][row["in_flow_id"]]
        pv.out_flow_id          = h[:flo][row["out_flow_id"]]
        pv.technology_set_id    = h[:mkt][row["technology_set_id"]]
        pv.technology_subset_id = h[:mkt][row["technology_subset_id"]]
        pv.scenario_id          = h[:sce][row["scenario_id"]]
        pv.time_slice           = row["time_slice"]
        pv.year                 = row["year"]
        pv.value                = row["value"]
        pv.source               = row["source"]
        pv.energy_system        = self
        pv.save
      end

      ZipTools::readline_zip(filename,DemandDriverValue) do |row|
        d = DemandDriverValue.new(demand_driver_id: h[:dmd][row["demand_driver_id"]],
                                  year:             row["year"],
                                  value:            row["value"],
                                  source:           row["source"])
        d.save
      end

    ensure
      PaperTrail.enabled = paper_trail_state
    end

  end

  # Return a zipped file which contains the complete energy system
  def zip(filename,subset_ids=nil)

    Zip::ZipOutputStream.open(filename) do |zipfile|
      headers = %W(name description first_year nb_periods period_duration)
      ZipTools::write_csv_into_zip(zipfile,EnergySystem, headers, [self.id]) do |e,csv|
        csv << e.attributes.values_at(*headers)
      end
      headers = %W(id name description sets)
      ids     = self.technologies.map(&:id)
      ZipTools::write_csv_into_zip(zipfile,Technology, headers, ids) do |t,csv|
        csv << [t.id,t.name,t.description,t.set_list.join(',')]
      end
      headers = %W(id name description sets demand_driver_id default_demand_elasticity projection_base_year)
      ids     = self.commodities.map(&:id)
      ZipTools::write_csv_into_zip(zipfile,Commodity, headers, ids) do |c,csv|
        csv << [c.id,c.name,c.description,c.set_list.join(','),c.demand_driver_id,
                c.default_demand_elasticity,c.projection_base_year]
      end
      headers = %W(id type technology_id commodities)
      ids     = Flow.where(technology_id: self.technologies).map(&:id)
      ZipTools::write_csv_into_zip(zipfile,Flow, headers, ids ) do |f,csv|
        csv << [f.id,f.class,f.technology_id,f.commodity_ids.join(' ')]
      end
      headers = %W(id name description)
      ids     = self.demand_drivers.map(&:id)
      ZipTools::write_csv_into_zip(zipfile, DemandDriver, headers, ids) do |p,csv|
        csv << p.attributes.values_at(*headers)
      end
      headers = %W(demand_driver_id year value source)
      ids     = DemandDriverValue.where(demand_driver_id: self.demand_drivers).map(&:id)
      ZipTools::write_csv_into_zip(zipfile, DemandDriverValue, headers, ids) do |p,csv|
        csv << p.attributes.values_at(*headers)
      end
      headers = %W(parameter_name technology_id commodity_id commodity_set_id flow_id in_flow_id out_flow_id technology_set_id technology_subset_id time_slice year value source scenario_id)
      ids     = self.parameter_values.map(&:id)
      ZipTools::write_csv_into_zip(zipfile, ParameterValue, headers, ids) do |pv,csv|
        csv << [pv.parameter.name,pv.technology_id,pv.commodity_id,pv.commodity_set_id,pv.flow_id,
                pv.in_flow_id,pv.out_flow_id,pv.technology_set_id,pv.technology_subset_id,pv.time_slice,
                pv.year,pv.value,pv.source,pv.scenario_id]
      end
      headers = %W(id name description technologies)
      ids     = self.technology_sets.map(&:id)
      ZipTools::write_csv_into_zip(zipfile, TechnologySet, headers, ids) do |m,csv|
        csv << [m.id,m.name,m.description,m.technology_ids.join(' '),m.set_list.join(',')]
      end
      headers = %W(id name description commodities)
      ids     = self.commodity_sets.map(&:id)
      ZipTools::write_csv_into_zip(zipfile, CommoditySet, headers, ids) do |a,csv|
        csv << [a.id,a.name,a.description,a.commodity_ids.join(' '),a.set_list.join(',')]
      end
      headers = %W(id name)
      ids     = self.scenarios.map(&:id)
      ZipTools::write_csv_into_zip(zipfile, Scenario, headers, ids) do |a,csv|
        csv << [a.id,a.name]
      end
    end

  end

  # Initialization of the energy system
  def setup
    # Base scenario
    s = Scenario.create(name: "BASE", energy_system: self)
    # Fraction Parameter
    p = Parameter.find_by_name("fraction")
    attr = {parameter: p, energy_system: self, scenario: s}
    ParameterValue.create(attr.merge(time_slice: "WD", value: 0.3333333333))
    ParameterValue.create(attr.merge(time_slice: "WN", value: 0.1666666667))
    ParameterValue.create(attr.merge(time_slice: "SD", value: 0.3333333333))
    ParameterValue.create(attr.merge(time_slice: "SN", value: 0.1666666667))
    ParameterValue.create(attr.merge(time_slice: "ID", value: 0.3333333333))
    ParameterValue.create(attr.merge(time_slice: "IN", value: 0.0833333333))
  end

end