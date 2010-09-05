require 'etem'

class Commodity < ActiveRecord::Base
  include Etem

  acts_as_taggable_on :sets, :sectors
  acts_as_identifiable :prefix => "c"

  has_and_belongs_to_many :flows
  has_many :parameter_values, :dependent => :delete_all
  belongs_to :demand_driver, :class_name => Parameter

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_format_of :name, :with => /\A[a-zA-Z\d-]+\z/,  :message => "Please use only regular letters, numbers or symbol '-' in name"

  scope :activated, where(:activated => true)

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

  def demand_values
    return [] unless demand?
    dm = Parameter.find_by_name('demand')
    dv =
    if self.demand_driver_id
      update_etem_options

      dv = self.parameter_values.where("parameter_id = ? AND year = ?", dm, first_year).first      
      base_year_value = dv ? dv.value : 0
      
      driver_values = ParameterValue.where(:parameter_id=>self.demand_driver_id).order(:year).collect{|pv| [pv.year,pv.value]}
      demand_projection(driver_values,base_year_value,self.demand_elasticity)
    else
      self.parameter_values.where(:parameter_id=>dm).order(:year).collect{|pv| [pv.year,pv.value]}
    end
  end

  def parameter_values_for(parameters)
    parameters = Array(parameters)
    param_ids = Parameter.where("name IN (?)",parameters).order(:name).map(&:id)
    self.parameter_values.where("parameter_id IN (?)",param_ids).order(:year)
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
      self.parameter_values.all.each { |pv|
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
    c.description = self.description
    c.save
    c.set_list = self.set_list.join(", ")
    c.save
    self.parameter_values.each { |pv|
      attributes = pv.attributes
      attributes.delete(["commodity_id","created_at","updated_at"])
      c.parameter_values << ParameterValue.create(attributes)
    }
    c.save
    c
  end

end