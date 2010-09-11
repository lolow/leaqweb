require 'etem'

class Commodity < ActiveRecord::Base
  include Etem
  
  versioned

  acts_as_taggable_on :sets, :sectors
  acts_as_identifiable :prefix => "c"

  has_and_belongs_to_many :flows
  has_many :parameter_values, :dependent => :delete_all
  
  belongs_to :demand_driver, :class_name => Parameter
  has_many :combustions, :dependent => :delete_all

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_format_of :name, :with => /\A[a-zA-Z\d-]+\z/,  :message => "Please use only regular letters, numbers or symbol '-' in name"
  
  scope :pollutant, tagged_with("POLL")
  scope :energy_carrier, tagged_with("ENC")
  scope :demand, tagged_with("DEM")
  

  def out_flows
    OutFlow.joins(:commodities).where("commodities.id"=>self)
  end

  def in_flows
    InFlow.joins(:commodities).where("commodities.id"=>self)
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
    self.parameter_values.joins(:parameter).where("parameters.name"=>Array(parameters)).order("parameters.name").order(:year)
  end
  
  def self.find_by_list_name(list)
    list.split(",").uniq.collect{|c|Commodity.find_by_name(c)}.compact
  end

  def to_s
    self.name
  end

  def duplicate
    c = Commodity.new
    name = self.name + "-01"
    while Commodity.find_by_name(name)
      name.succ!
    end
    c.name = name
    c.description = self.description
    c.save
    c.set_list = self.set_list.join(", ")
    c.save
    params_list = %w{demand frac_dem} + %w{network_efficiency peak_reserve} + 
                  %w{cost_imp cost_exp imp_bnd_lo imp_bnd_fx imp_bnd_up} + 
                  %w{exp_bnd_lo exp_bnd_fx exp_bnd_up } + 
                  %w{com_net_bnd_up_t com_net_bnd_up_ts}
    params = Parameter.where(:name=>params_list).map(&:id)
    self.parameter_values.where(:parameter_id => params).each { |pv|
        c.parameter_values << ParameterValue.create(pv.attributes.delete(["commodity_id","created_at","updated_at"]))
    }
    c.save
    c
  end

end