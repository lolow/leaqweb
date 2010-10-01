class Combustion < ActiveRecord::Base
  versioned
  
  belongs_to :fuel, :class_name => "Commodity"
  belongs_to :pollutant, :class_name => "Commodity"

  validates :value, :presence => true, :numericality => true
end
