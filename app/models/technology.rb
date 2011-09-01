require 'etem'

class Technology < ActiveRecord::Base
  include Etem

  #Interfaces
  has_paper_trail
  acts_as_taggable_on :sets

  #Relations
  has_many :out_flows, :dependent => :destroy
  has_many :in_flows, :dependent => :destroy
  has_many :flows, :dependent => :destroy
  has_many :parameter_values, :dependent => :delete_all
  has_and_belongs_to_many :markets

  #Validations
  validates :name, :presence => true,
            :uniqueness => true,
            :format => {:with => /\A[a-zA-Z\d-]+\z/,
                        :message => "Please use only letters, numbers or '-' in name"}

  # Categories [name,value]
  # sets in value has to be sorted by alphabetical order!!
  CATEGORIES = [
      ["Disabled", ""],
      ["Conversion Technology", "P"],
      ["Fuel Technology", "FUELTECH,P"],
      ["Demand device", "DMD,P"]
  ]

  scope :activated, tagged_with("P")
  scope :matching_text, lambda {|text| where(['name LIKE ? OR description LIKE ?'] + ["%#{text}%"] * 2) }
  scope :matching_tag, lambda {|tag| tagged_with(tag) if (tag && tag!="" && tag != "null")}

  def flow_act
    ParameterValue.of("flow_act").technology(self).first.flow
  end

  def flow_act=(flow)
    pv = ParameterValue.of("flow_act").technology(self).first
    if pv
      ParameterValue.update(pv.id, :flow=>flow)
    else
      p = Parameter.find_by_name("flow_act")
      ParameterValue.create!(:parameter=>p, :technology=>self, :flow=>flow, :value=>0)
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

  def parameter_values_for(parameters)
    ParameterValue.of(Array(parameters)).where(:technology_id=>self).order(:year)
  end

  def to_s
    self.name
  end

  # Duplicate the technology
  def duplicate(new_name=nil)
    new_name = next_available_name(Technology, self.name) unless new_name
    t = Technology.create(:name => new_name,
                          :description => self.description,
                          :set_list => self.set_list.join(','))
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
            ["input","output"]
    parameter_values_for(parameters).each { |pv|
      attributes = pv.attributes
      %w{flow_id in_flow_id out_flow_id}.each do |att|
        attributes[att] = flow_hash[attributes[att]]
      end
      attributes.delete("technology_id")
      t.parameter_values << ParameterValue.create(attributes)
    }
    t.save
    t
  end

  # Read input/output parameters to create/update eff_flo / flo_shr_fx parameters
  def preprocess_input_output

    #Read all input/output parameters
    io = ["input", "output"].collect { |p| parameter_values_for(p) }
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
        efficiency = value[1].values.sum/value[0].values.sum
        pv = ParameterValue.of("eff_flo").where("in_flow_id=? AND out_flow_id=?", kk[0], kk[1]).first
        if pv
          ParameterValue.update(pv.id, :value=>efficiency,
                                :source=>"Preprocessed")
        else
          param = Parameter.find_by_name("eff_flo")
          ParameterValue.create(:parameter_id=>param.id,
                                :technology_id=>self.id,
                                :in_flow_id=>kk[0],
                                :out_flow_id=>kk[1],
                                :value=>efficiency,
                                :source=>"Preprocessed")
        end

        #flo_share_fx
        [0, 1].each do |x|
          param = Parameter.find_by_name("flo_share_fx")
          c = Flow.find(kk[x]).commodities
          if c.size > 1
            ParameterValue.destroy_all(:parameter_id=>param.id, :flow_id=>kk[x])
            total = value[x].values.sum
            #ensure sum is equal to 1
            coef = {}
            c.each { |j| coef[j.id] = (value[x][j.id]/total * 10**10).round.to_f / 10**10 }
            if coef.values.sum > 1
              coef[coef.keys.first] -= coef.values.sum - 1
            end
            #set coefficients
            c.each do |j|
              ParameterValue.create(:parameter_id=>param.id,
                                    :technology_id=>self.id,
                                    :flow_id=>kk[x],
                                    :commodity_id=>j.id,
                                    :value=> coef[j.id],
                                    :source=>"Preprocessed")
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
    Combustion.where(:pollutant_id=>pollutant).each { |c| coefs[c.fuel_id] = c.value }
    if fuels.size == 1
      coefs[fuels.first.id]
    else
      share = self.parameter_values_for("flo_share_fx").where(:flow_id=>in_flow)
      share.collect! { |s| coefs[s.commodity_id] * s.value }
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

  def self.find_by_list_name(list)
    Technology.where(:name=>list.split(","))
  end
end