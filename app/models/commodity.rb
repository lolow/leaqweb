class Commodity < ActiveRecord::Base
  acts_as_taggable_on :sets

  has_and_belongs_to_many :flows
  has_many :parameter_values
  
  validates_presence_of :name
  validates_uniqueness_of :name
end
