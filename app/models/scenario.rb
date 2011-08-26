class Scenario < ActiveRecord::Base
  acts_as_nested_set
  has_many :parameter_values
  scope :matching_text, lambda {|text| where(['name LIKE ?'] + ["%#{text}%"]) }
  scope :matching_tag
end
