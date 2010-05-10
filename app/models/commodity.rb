class Commodity < ActiveRecord::Base
  acts_as_taggable_on :sets
  acts_as_identifiable :prefix => "c"

  has_and_belongs_to_many :flows
  has_many :parameter_values
  
  validates_presence_of :name
  validates_uniqueness_of :name

  named_scope :activated, :conditions => {:activated => true}

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

  def activate(bool)
    self.update_attributes!(:activated => bool)
    ParameterValue.transaction{
      self.parameter_values.find(:all).each { |pv|
        pv.activated = self.activated
        pv.save
      } rescue nil
    }
  end

  def copy
    c = Commodity.new
    name = self.name + " 01"
    while Commodity.find_by_name(name)
      name.succ!
    end
    c.name = name
    c.sets = self.sets
    c.save
    self.parameter_values.each { |pv|
      attributes = pv.attributes
      attributes.delete(["commodity_id","created_at","updated_at"])
      c.parameter_values << ParameterValue.create(attributes)
    }
  end

end