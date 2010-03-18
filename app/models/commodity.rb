class Commodity < ActiveRecord::Base
  acts_as_taggable_on :sets

  has_and_belongs_to_many :flows
  has_many :parameter_values
  
  validates_presence_of :name
  validates_uniqueness_of :name

  def out_flows
    self.flows.select{|f| f.is_a? OutFlow}
  end

  def in_flows
    self.flows.select{|f| f.is_a? InFlow}
  end

  def produced_by
    self.out_flows.map{|f| f.technology}
  end

  def consumed_by
    self.in_flows.map{|f| f.technology}
  end

  def demand?
    self.set_list.include? "DEM"
  end

  def parameter_values_for(parameter)
    param = Parameter.find_by_name(parameter)
    param.parameter_values.find(:all,:conditions => { :commodity_id => self },
                                     :order => "year")
  end

end