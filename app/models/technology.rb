class Technology < ActiveRecord::Base
  acts_as_taggable_on :sets, :sectors
  
  has_and_belongs_to_many :locations
  has_many :out_flows, :dependent => :destroy
  has_many :in_flows, :dependent => :destroy
  has_many :flows, :dependent => :destroy
  has_many :parameter_values, :dependent => :delete_all
  
  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :activated, :conditions => {:activated => true}
  
  acts_as_identifiable :prefix => "t"
  
  def flow_act
    p = Parameter.find_by_name("flow_act")
    pv = p.parameter_values.find(:first,:conditions=>{:technology_id=>self})
    pv.flow
  end

  def flow_act=(flow)
    p = Parameter.find_by_name("flow_act")
    pv = p.parameter_values.find(:first,:conditions=>{:technology_id=>self})
    if pv
      ParameterValue.update(pv.id,:flow=>flow)
    else
      ParameterValue.create!(:parameter=>p,:technology=>self,:flow=>flow,:value=>0)
    end
  end

  def commodities
    self.flows.collect{|f| f.commodities}.flatten.uniq
  end

  def outputs
    self.out_flows.collect{|f| f.commodities}.flatten.uniq
  end

  def inputs
    self.in_flows.collect{|f| f.commodities}.flatten.uniq
  end
  
  def parameter_values_for(parameters)
    parameters = [parameters] unless parameters.is_a? Array
    param_ids = Parameter.find(:all,
      :conditions => ["name IN (?)",parameters],
      :order => "name").map &:id
    self.parameter_values.find(:all, 
      :conditions => ["parameter_id IN (?)",param_ids],
      :order => "year")
  end

  def to_s
    self.name
  end

  def copy
    t = Technology.new
    name = self.name + " 01"
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
    self.parameter_values.each { |pv|
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
        pv = ParameterValue.find(:first,:conditions=>{:parameter_id=>param.id,:in_flow_id=>kk[0],:out_flow_id=>kk[1]})
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
            c.each do |j|
              v = value[x][j.id]/total
              ParameterValue.create(:parameter_id=>param.id,
                :technology_id=>self.id,
                :flow_id=>kk[x],
                :commodity_id=>j.id,
                :value=> v,
                :source=>"Preprocessed")
            end
          end
        end

      end
    end


  end
  
end
