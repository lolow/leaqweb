class ParameterValue < ActiveRecord::Base
  belongs_to :parameter
  belongs_to :technology
  belongs_to :commodity
  belongs_to :flow
  belongs_to :out_flow
  belongs_to :in_flow
  belongs_to :location
  
  validates_presence_of :value
  validates_numericality_of :value

  validates_presence_of :parameter
  
  validates_numericality_of :year, :allow_nil => true, :only_integer => true, :greater_than => -1

  validates_inclusion_of :time_slice, :in => %w(AN IN ID SN SD WN WD), :allow_nil => true
end
