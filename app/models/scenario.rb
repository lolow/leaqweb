class Scenario < ActiveRecord::Base
  acts_as_nested_set
  has_many :parameter_values
end
