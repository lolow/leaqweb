class Combustion < ActiveRecord::Base

  #Interfaces
  has_paper_trail

  #Relations
  belongs_to :fuel, :class_name => "Commodity"
  belongs_to :pollutant, :class_name => "Commodity"

  #Validations
  validates :value, :presence => true, :numericality => true

  #Scopes
  scope :matching_text, lambda {|text| where(['commodities.name LIKE ? OR pollutants_combustions.name LIKE ? OR combustions.source LIKE ?'] + ["%#{text}%"] * 3 ) }
  scope :matching_tag #empty because not taggable

end
