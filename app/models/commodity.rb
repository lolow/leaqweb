class Commodity < ActiveRecord::Base
  acts_as_taggable_on :sets
  acts_as_identifiable :prefix => "c"

  has_and_belongs_to_many :flows
  has_many :parameter_values
  
  validates_presence_of :name
  validates_uniqueness_of :name
  #validates_format_of  :name , :with => /^[A-Za-z_0-9]*\z/, :message => "Cannot contain White Space"

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

  def parameter_values_for(parameters)
    parameters = [parameters] unless parameters.is_a? Array
    param_ids = Parameter.find(:all,
                               :conditions => ["name IN (?)",parameters],
                               :order => "name").map &:id
    self.parameter_values.find(:all,
                               :conditions => ["parameter_id IN (?)",param_ids],
                               :order => "year")
  end

  def self.find_by_list_name(list)
    list.split(",").uniq.collect{|c|Commodity.find_by_name(c)}.compact
  end

  def to_s
    self.name
  end
  
end