class Technology < ActiveRecord::Base
  acts_as_taggable_on :sets
  
  has_and_belongs_to_many :locations
  has_many :out_flows
  has_many :in_flows
  has_many :flows
  has_many :parameter_values
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of  :name , :with => /^[A-Za-z_0-9]*\z/, :message => "Cannot contain White Space"
  
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
  
end
