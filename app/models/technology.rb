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

require 'etem'

class Technology < ActiveRecord::Base
  include Etem

  #Interfaces
  has_paper_trail
  acts_as_taggable_on :sets

  #Relations
  belongs_to :energy_system
  has_many :out_flows, dependent: :destroy
  has_many :in_flows,  dependent: :destroy
  has_many :flows,     dependent: :destroy
  has_many :parameter_values, dependent: :delete_all
  has_and_belongs_to_many :technology_sets

  #Validations
  validates :energy_system, presence: true
  validates :name, presence: true,
                   uniqueness:  {scope: :energy_system_id},
                   format: {with: /\A[a-zA-Z\d-]+\z/, message: "Please use only letters, numbers or '-' in name"}

  # Categories [name,value]
  # sets in value has to be sorted by alphabetical order!!
  CATEGORIES = [
      ["Disabled", ""],
      ["Conversion Technology", "P"],
      ["Fuel Technology", "FUELTECH,P"],
      ["Demand device", "DMD,P"]
  ]

  #Scopes
  scope :activated, tagged_with("P")
  scope :matching_text, lambda {|text| where(['name LIKE ? OR description LIKE ?'] + ["%#{text}%"] * 2) }
  scope :matching_tag, lambda {|tag| tagged_with(tag) if (tag && tag!="" && tag != "null")}
  scope :find_by_list_name, lambda {|list| where(name: list.split(","))}

  def flow_act
    ParameterValue.of("flow_act").technology(self).first.flow
  end

  def flow_act=(flow)
    p = Parameter.find_by_name("flow_act")
    pv = parameter_values.where(parameter_id: p.id).first
    if pv
      ParameterValue.update(pv.id, flow: flow)
    else
      ParameterValue.create(energy_system: energy_system,
                            parameter:     p,
                            technology:    self,
                            flow:          flow,
                            value:         0,
                            scenario:      energy_system.base_scenario)
    end
  end

  def commodities
    collect_commodities(flows)
  end

  def outputs
    collect_commodities(out_flows)
  end

  def inputs
    collect_commodities(in_flows)
  end

  def collect_commodities(flows)
    Commodity.joins(:flows).where("flows.id"=>flows.map(&:id))
  end

  def values_for(parameters,scenario_id)
    parameter_values.of(Array(parameters)).where(scenario_id: scenario_id).order(:year)
  end

  def to_s
    self.name
  end

  # Duplicate the technology
  def duplicate(new_name=nil)
    new_name = next_available_name(Technology, self.name) unless new_name
    t = Technology.create(name:          new_name,
                          description:   self.description,
                          set_list:      self.set_list.join(','),
                          energy_system: energy_system)
    flow_hash = {}
    self.in_flows.each { |f|
      ff = InFlow.create
      flow_hash[f.id] = ff.id
      f.commodities.each { |c| ff.commodities << c }
      t.flows << ff
    }
    self.out_flows.each { |f|
      ff = OutFlow.create
      flow_hash[f.id] = ff.id
      f.commodities.each { |c| ff.commodities << c }
      t.flows << ff
    }
    parameters = signature.keys.select{|k| signature[k] &&
            (signature[k].include?("technology")||signature[k].include?("flow")||signature[k].include?("in_flow"))} +
            %w(input output)
    Scenario.all.each do |scen|
      values_for(parameters,scen.id).each do |pv|
        attributes = pv.attributes
        %w{flow_id in_flow_id out_flow_id}.each do |att|
          attributes[att] = flow_hash[attributes[att]]
        end
        attributes.delete("technology_id")
        t.parameter_values << ParameterValue.create(attributes)
      end
    end
    t.save
    t
  end

  # Read input/output parameters to create/update eff_flo / flo_shr_fx parameters
  def preprocess_input_output(scenario_id)

    #Read all input/output parameters
    io = %w(input output).collect { |p| values_for(p,scenario_id) }
    return if (io[0].size*io[1].size)==0

    #Classify inflow-outflow
    p = Hash.new
    io.each_index do |i|
      io[i].each do |r|
        key = "#{r.in_flow_id}-#{r.out_flow_id}"
        p[key] = {} unless p[key]
        p[key][i] = Hash.new(0) unless p[key][i]
        p[key][i][r.commodity_id] = r.value
      end
    end

    #create/update eff_flo
    p.each do |key, value|
      # check if input and outputs both exists
      if value.keys == [0, 1]

        kk = key.split("-")

        #eff-flo
        tot = value[0].values.sum
        efficiency = [value[1].values.sum/tot,0].max
        pv = ParameterValue.of("eff_flo").where("in_flow_id=? AND out_flow_id=?", kk[0], kk[1]).first
        if pv
          ParameterValue.update(pv.id, value: efficiency, source: "Preprocessed")
        else
          param = Parameter.find_by_name("eff_flo")
          ParameterValue.create(parameter_id: param.id,
                                technology_id: self.id,
                                in_flow_id: kk[0],
                                out_flow_id: kk[1],
                                value: efficiency,
                                scenario_id: scenario_id,
                                energy_system: energy_system,
                                source: "Preprocessed")
        end

        #flo_share_fx
        [0, 1].each do |x|
          param = Parameter.find_by_name("flo_share_fx")
          c = Flow.find(kk[x]).commodities
          if c.size > 1
            ParameterValue.destroy_all(parameter_id: param.id, flow_id: kk[x])
            total = value[x].values.sum
            #ensure sum is equal to 1
            coef = {}
            c.each { |j| coef[j.id] = [0,(value[x][j.id]/total*10**10).round(0).to_f/10**10].max }
            # Erreur arrondi
            if coef.values.sum > 1
              diff = coef.values.sum - 1
              selected_k = coef.select{|k,v| v>diff}.first.first
              coef[selected_k] -= diff
            end
            #set coefficients
            c.each do |j|
              pv = ParameterValue.create(parameter_id: param.id,
                                         technology_id: self.id,
                                         flow_id: kk[x],
                                         commodity_id: j.id,
                                         value: coef[j.id],
                                         scenario_id: scenario_id,
                                         energy_system: energy_system,
                                         source: "Preprocessed")
              pv
            end
          end
        end

      end
    end
  end

  # Compute eff_flo between two flows when out_flow is a pollutant
  def combustion_factor(in_flow, out_flow)
    in_flow = self.in_flows.first unless in_flow
    fuels = in_flow.commodities
    pollutant = out_flow.commodities.first
    coefs = Hash.new(0)
    Combustion.where(pollutant: pollutant.name).each { |c| coefs[c.fuel] = c.value }
    if fuels.size == 1
      coefs[fuels.first.name]
    else
      share = self.values_for("flo_share_fx",energy_system.base_scenario.id).where(flow_id: in_flow)
      share.collect! { |s| coefs[s.commodity.name] * s.value }
      share.inject(0) { |sum, x| sum+x }
    end
  end

  #return the corresponding set list from the CATEGORIES array
  def matching_set_list
    my_set = self.set_list.sort.join(",")
    s = nil
    CATEGORIES.each do |c|
      if c[1]==my_set
        s = c[1]
        break
      end
    end
    s
  end

end
