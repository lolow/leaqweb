class Flow < ActiveRecord::Base
  belongs_to :technology
  has_many :parameter_values
  has_and_belongs_to_many :commodities
end
