class Combustion < ActiveRecord::Base
  versioned
  
  belongs_to :fuel, :class_name => "Commodity"
  belongs_to :pollutant, :class_name => "Commodity"
  
  validates_presence_of :value
  validates_numericality_of :value
  
end
