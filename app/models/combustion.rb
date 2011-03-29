class Combustion < ActiveRecord::Base

  has_paper_trail

  #Relations
  belongs_to :fuel, :class_name => "Commodity"
  belongs_to :pollutant, :class_name => "Commodity"

  #Validations
  validates :value, :presence => true, :numericality => true

  def parameter_values_for(parameters)
    Combustion.all
  end

end
