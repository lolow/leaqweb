class ParameterValue < ActiveRecord::Base
  belongs_to :parameter
  belongs_to :technology
  belongs_to :commodity
  belongs_to :flow
  belongs_to :out_flow
  belongs_to :in_flow
  belongs_to :location
  
  validates_presence_of :value
end
