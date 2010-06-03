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
    self.parameter_values.each { |pv|
      attributes = pv.attributes
      attributes.delete(["technology_id","created_at","updated_at"])
      t.parameter_values << ParameterValue.create(attributes)
    }
    t.save
    self.flows.each { |f|
      case f.type
      when "InFlow"
        f0 = InFlow.new
      when "OutFlow"
        f0 = OutFlow.new
      end
      f.commodities.each {|c|
        f0.commodities << c
      }
      t.flows << f0
    }
    t.save
    t
  end
  
end
