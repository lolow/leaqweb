class Combustion < ActiveRecord::Base
  #Relations
  belongs_to :fuel, :class_name => "Commodity"
  belongs_to :pollutant, :class_name => "Commodity"

  #Validations
  validates :value, :presence => true, :numericality => true
end
