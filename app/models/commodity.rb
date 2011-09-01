require 'etem'

class Commodity < ActiveRecord::Base
  include Etem

  #Interfaces
  has_paper_trail
  acts_as_taggable_on :sets

  #Relations
  has_and_belongs_to_many :flows
  has_many :parameter_values, :dependent => :delete_all
  belongs_to :demand_driver
  has_many :combustions, :dependent => :destroy, :foreign_key => :fuel_id
  has_many :combustions, :dependent => :destroy, :foreign_key => :pollutant_id
  has_and_belongs_to_many :aggregates

  #Validations
  validates :name, :presence => true,
            :uniqueness => true,
            :format => {:with => /\A[a-zA-Z\d-]+\z/,
                        :message => "Please use only letters, numbers or '-' in name"}

  # Categories [name,value]
  # sets in value has to be sorted by alphabetical order!!
  CATEGORIES = [
      ["Disabled", ""],
      ["Energy carrier [import]", "C,ENC,IMP"],
      ["Energy carrier [export]", "C,ENC,EXP"],
      ["Energy carrier [import+export]", "C,ENC,EXP,IMP"],
      ["Energy carrier [only]", "C,ENC"],
      ["Pollutant", "C,POLL"],
      ["Demand", "C,DEM"]
  ]

  scope :pollutants, tagged_with("POLL")
  scope :energy_carriers, tagged_with("ENC")
  scope :demands, tagged_with("DEM")
  scope :activated, tagged_with("C")
  scope :imports, tagged_with("IMP")
  scope :exports, tagged_with("EXP")
  scope :matching_text, lambda {|text| where(['name LIKE ? OR description LIKE ?'] + ["%#{text}%"] * 2) }
  scope :matching_tag, lambda {|tag| tagged_with(tag) if (tag && tag!="" && tag != "null")}

  def out_flows
    OutFlow.joins(:commodities).where("commodities.id"=>id)
  end

  def in_flows
    InFlow.joins(:commodities).where("commodities.id"=>id)
  end

  def produced_by
    ids = OutFlow.joins(:commodities).where("commodities.id"=>id).select(:technology_id).map{|f|f.technology_id}
    Technology.where(:id=>ids)
  end

  def consumed_by
    ids = InFlow.joins(:commodities).where("commodities.id"=>id).select(:technology_id).map{|f|f.technology_id}
    Technology.where(:id=>ids)
  end

  def activated?
    self.set_list.include? "C"
  end

  def demand?
    self.set_list.include? "DEM"
  end

  def pollutant?
    self.set_list.include? "POLL"
  end

  def type_name
    return "Demand" if set_list.include? "DEM"
    return "Pollutant" if set_list.include? "POLLS"
    return "Import+Export" if set_list.include?("IMP") && set_list.include?("EXP")
    return "Import" if set_list.include? "IMP"
    return "Export" if set_list.include? "EXP"
    return "Energy Carrier"
  end

  #return demand_values
  def demand_values(first_year)
    return [] unless demand?
    if demand_driver
      dv = parameter_values.of("demand").where(:year=>first_year).first
      base_year_value = dv ? dv.value : 0
      driver_values = ParameterValue.of(demand_driver.to_s).order(:year)
      driver_values.collect! { |pv| [pv.year, pv.value] }
      demand_projection(driver_values, base_year_value, self.demand_elasticity)
    else
      parameter_values.of("demand").order(:year).collect { |pv| [pv.year, pv.value] }
    end
  end

  def demand_elasticity
    elas = Hash.new(self.default_demand_elasticity)
    parameter_values_for('demand_elasticity').each do |pv|
      elas[pv.year.to_i] = pv.value
    end
    elas
  end

  def parameter_values_for(parameters)
    ParameterValue.of(Array(parameters)).where(:commodity_id=>self).order(:year)
  end

  def self.find_by_list_name(list)
    Commodity.where(:name=>list.split(","))
  end

  def to_s
    name
  end

  def duplicate
    c = Commodity.create(:name => next_available_name(Commodity, name),
                         :description => description,
                         :set_list => set_list.join(", "),
                         :demand_driver => demand_driver)
    parameters = signature.keys.select{|k| signature[k] && signature[k].include?("commodity")}
    parameter_values.of(parameters).each do |pv|
      c.parameter_values << ParameterValue.create(pv.attributes)
    end
    c.save
    c
  end

  #return the corresponding set list from the CATEGORIES array
  def matching_set_list
    my_set = self.set_list.sort.join(",")
    s = nil
    CATEGORIES.each do |c|
      if c[1]==my_set
        s = c[1]
        break
      end
    end
    s
  end



end