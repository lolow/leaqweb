class Technology < ActiveRecord::Base

  versioned

  acts_as_taggable_on :sets, :sectors

  has_many :out_flows, :dependent => :destroy
  has_many :in_flows, :dependent => :destroy
  has_many :flows, :dependent => :destroy
  has_many :parameter_values, :dependent => :delete_all
  
  validates_presence_of :name
  validates_uniqueness_of :name

  validates_format_of :name, :with => /\A[a-zA-Z\d-]+\z/,  :message => "Please use only regular letters, numbers or symbol '-' in name"
  
  acts_as_identifiable :prefix => "t"
  
  def flow_act
    p = Parameter.find_by_name("flow_act")
    pv = p.parameter_values.where(:technology_id=>self).first
    pv.flow
  end

  def flow_act=(flow)
    p = Parameter.find_by_name("flow_act")
    pv = p.parameter_values.where(:technology_id=>self).first
    if pv
      ParameterValue.update(pv.id,:flow=>flow)
    else
      ParameterValue.create!(:parameter=>p,:technology=>self,:flow=>flow,:value=>0)
    end
  end

  def commodities
    collect_commodities(self.flows)
  end

  def outputs
    collect_commodities(self.out_flows)
  end

  def inputs
    collect_commodities(self.in_flows)
  end
  
  def collect_commodities(flows)
    flows.includes(:commodities).collect{|f| f.commodities}.flatten.uniq
  end
  
  def parameter_values_for(parameters)
    self.parameter_values.joins(:parameter).where("parameters.name"=>Array(parameters)).order("parameters.name").order(:year)
  end

  def to_s
    self.name
  end

  # Duplicate the technology
  def duplicate
    t = Technology.new
    name = self.name + "-01"
    while Technology.find_by_name(name)
      name.succ!
    end
    t.name = name
    t.description = description
    t.set_list = self.set_list.join(', ')
    t.save
    flow_corr = Hash.new
    self.flows.each { |f|
      case f.type
      when "InFlow"
        f0 = InFlow.create
      when "OutFlow"
        f0 = OutFlow.create
      end
      flow_corr[f.id] = f0.id
      f.commodities.each {|c|
        f0.commodities << c
      }
      t.flows << f0
    }
    t.save
    params_list = %w{input output} + %w{eff_flo } + %w{flo_bnd_lo flo_bnd_fx flo_bnd_up} +
      %w{flo_share_lo flo_share_fx flo_share_up} +
      %w{peak_prod cost_delivery act_flo} + %w{fixed_cap} + 
      %w{life avail cap_act  avail_factor} + %w{cost_vom cost_fom cost_icap} +
      %w{act_bnd_lo act_bnd_fx act_bnd_up} +
      %w{cap_bnd_lo cap_bnd_fx cap_bnd_up} +
      %w{icap_bnd_lo icap_bnd_fx icap_bnd_up}
    params = Parameter.where(:name=>params_list).map(&:id)
    self.parameter_values.where(:parameter_id=>params).each { |pv|
      attributes = pv.attributes
      attributes[:flow_id] = flow_corr[attributes[:flow_id]]
      attributes[:in_flow_id] = flow_corr[attributes[:in_flow_id]]
      attributes[:out_flow_id] = flow_corr[attributes[:out_flow_id]]
      attributes.delete(["technology_id","created_at","updated_at"])
      t.parameter_values << ParameterValue.create(attributes)
    }
    t.save
    self.locations.each { |l|
      t.locations << l
    }
    t.save
    t
  end

  # Read input/output parameters to create/update eff_flo / flo_shr_fx parameters
  def preprocess_input_output
    
    #Read parameters
    io = []
    io << self.parameter_values_for("input")
    return if io[0].size==0
    io << self.parameter_values_for("output")
    return if io[1].size==0

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
    p.each do |key,value|
      # check if input and outputs both exists
      if value.keys == [0,1]
        
        kk = key.split("-")

        #eff-flo
        efficiency = value[1].values.sum/value[0].values.sum
        param = Parameter.find_by_name("eff_flo")
        pv = ParameterValue.where("parameter_id=? AND in_flow_id=? AND out_flow_id=?",param.id,kk[0],kk[1]).first 
        if pv
          pv.update_attributes(:value=>efficiency,:source=>"Preprocessed")
        else
          ParameterValue.create(:parameter_id=>param.id,:technology_id=>self.id,:in_flow_id=>kk[0],:out_flow_id=>kk[1],:value=>efficiency,:source=>"Preprocessed")
        end

        #flo_share_fx
        [0,1].each do |x|
          param = Parameter.find_by_name("flo_share_fx")
          c = Flow.find(kk[x]).commodities
          if c.size > 1
            ParameterValue.destroy_all(:parameter_id=>param.id,:flow_id=>kk[x])
            total = value[x].values.sum
            #ensure sum is equal to 1
            coef = {}
            c.each {|j| coef[j.id]= (value[x][j.id]/total * 10**10).round.to_f / 10**10 }
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
  def combustion_factor(in_flow,out_flow)
    in_flow = self.in_flows.first unless in_flow
    fuels = in_flow.commodities
    pollutant = out_flow.commodities.first
    coefs = Hash.new(0)
    Combustion.where(:pollutant_id=>pollutant).each{|c| coefs[c.fuel_id] = c.value }
    if fuels.size == 1
      return coefs[fuels.first.id]
    else
      share = self.parameter_values_for("flo_share_fx").where(:flow_id=>in_flow)
      share.collect!{ |s| coefs[s.commodity_id] * s.value }
      return share.inject(0){|sum,x| sum+x }
    end
  end

  # Create a fuel tech and its input/output if necessary
  def self.create_fuel_tech(input,output)

    #find_or_create commodities
    com = {}
    [input,output].each do |c|
      if Commodity.where(:name=>c).empty?
        com[c] = Commodity.create(:name=>c,:description=>"")
      else
        com[c] = Commodity.find_by_name(c)
      end
    end
    
    #check if a fuel tech already exists?
    if (com[input].consumed_by & com[output].produced_by).size > 0
      return nil
    end
    
    t = Technology.new
    name = "TECH-" + output
    while Technology.find_by_name(name)
      name.succ!
    end
    t.name = name
    t.description = "Fuel tech [" + input+"->"+output+"]"
    t.set_list = "FUELTECH"
    t.save
    t.locations << Location.first
    t.save
    fi = InFlow.create
    fi.commodities << com[input]
    t.flows << fi
    fo = OutFlow.create
    fo.commodities << com[output]
    t.flows << fo
    t.save
    p = Parameter.find_by_name("eff_flo")
    ParameterValue.create(:parameter  => p,
                          :technology => t,
                          :in_flow =>fi,
                          :out_flow =>fo,
                          :value => 1,
                          :source => "Fuel tech")
    t.flow_act = fi
    t
  end
    
end
