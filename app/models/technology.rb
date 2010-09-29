class Technology < ActiveRecord::Base

  versioned

  acts_as_taggable_on :sets, :sectors

  has_many :out_flows, :dependent => :destroy
  has_many :in_flows, :dependent => :destroy
  has_many :flows, :dependent => :destroy
  has_many :parameter_values, :dependent => :delete_all

  validates :name, :presence => true,
                   :uniqueness => true,
                   :format => { :with => /\A[a-zA-Z\d-]+\z/,
                                :message => "Please use only regular letters, numbers or symbol '-' in name" }
  
  acts_as_identifiable :prefix => "t"
  
  def flow_act
    ParameterValue.of("flow_act").technology(self).first.flow
  end

  def flow_act=(flow)
    pv = ParameterValue.of("flow_act").technology(self).first
    if pv
      ParameterValue.update(pv.id,:flow=>flow)
    else
      p = Parameter.find_by_name("flow_act")
      ParameterValue.create!(:parameter=>p,:technology=>self,:flow=>flow,:value=>0)
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
    ParameterValue.for(Array(parameters)).technology(self).order(:year)
  end

  def to_s
    self.name
  end

  # Duplicate the technology
  def duplicate
    t = Technology.create( :name => next_available_name(Technology,self.name),
                           :description => self.description,
                           :set_list => self.set_list.join(', ') )
    flow_hash = {}
    self.flows.each { |f|
      eval("ff = #{f.type}.create")
      flow_hash[f.id] = ff.id
      f.commodities.each {|c| ff.commodities << c }
      t.flows << ff
    }
    t.save
    params = Parameter.where(:name=>PARAM_TECHNOLOGIES).map(&:id)
    self.parameter_values.where(:parameter_id=>params).each { |pv|
      attributes = pv.attributes
      [:flow_id,:in_flow_id,:out_flow_id].each do |att|
        attributes[att] = flow_hash[attributes[att]]
      end
      attributes.delete(["technology_id","created_at","updated_at"])
      t.parameter_values << ParameterValue.create(attributes)
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
    t.description = "Fuel tech"
    t.set_list = "FUELTECH"
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
