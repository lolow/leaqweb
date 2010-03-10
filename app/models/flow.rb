class Flow < ActiveRecord::Base
  belongs_to :technology
  has_many :parameter_values
  has_many :commodities
end
