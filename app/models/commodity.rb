require 'etem'

class Commodity < ActiveRecord::Base
  include Etem

  versioned

  #Acts_as
  acts_as_taggable_on :sets
  acts_as_identifiable :prefix => "c"

  #Relations
  has_and_belongs_to_many :flows
  has_many :parameter_values, :dependent => :delete_all
  belongs_to :demand_driver
  has_many :combustions, :dependent => :delete_all, :foreign_key => :fuel_id
  has_many :combustions, :dependent => :delete_all, :foreign_key => :pollutant_id

  #Validations
  validates :name, :presence => true,
            :uniqueness => true,
            :format => {:with => /\A[a-zA-Z\d-]+\z/,
                        :message => VALID_NAME}

  # Categories [name,value]
  # sets in value has to be sorted!!
  CATEGORIES = [
      ["Disabled", ""],
      ["Energy carrier [import]", "C,ENC,IMP"],
      ["Energy carrier [export]", "C,ENC,EXP"],
      ["Energy carrier [import+export]", "C,ENC,EXP,IMP"],
      ["Energy carrier [only]", "C,ENC"],
      ["Demand", "C,DEM"],
      ["Aggregate", "AGG,C"]
  ]

  scope :pollutants, tagged_with("POLL")
  scope :energy_carriers, tagged_with("ENC")
  scope :demands, tagged_with("DEM")
  scope :activated, tagged_with("C")
  scope :imports, tagged_with("IMP")
  scope :exports, tagged_with("EXP")
  scope :aggregates, tagged_with("AGG")

  def out_flows
    OutFlow.joins(:commodities).where("commodities.id"=>self)
  end

  def in_flows
    InFlow.joins(:commodities).where("commodities.id"=>self)
  end

  def produced_by
    Technology.joins(:flows).where("flows.id"=>out_flows)
  end

  def consumed_by
    Technology.joins(:flows).where("flows.id"=>in_flows)
  end

  def demand?
    self.set_list.include? "DEM"
  end

  def pollutant?
    self.set_list.include? "POLL"
  end

  def demand_values
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
    parameter_values.of(PARAM_COMMODITIES).each do |pv|
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
