# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

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
