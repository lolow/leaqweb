class ParameterValue < ActiveRecord::Base

  versioned

  belongs_to :parameter
  belongs_to :technology
  belongs_to :commodity
  belongs_to :flow
  belongs_to :out_flow
  belongs_to :in_flow

  validates :value, :presence => true, :numericality => true
  validates :parameter, :presence => true
  validates :year, :numericality => {:only_integer => true, :minimum => -1}, :allow_nil => true
  validates :time_slices, :inclusion => { :in => %w(AN IN ID SN SD WN WD) }, :allow_nil => true

  scope :of, lambda { |names| joins(:parameter).where("parameters.name"=>names).order("parameters.name") }
  scope :technology, lambda { |tech| where(:technology_id=>tech) }
end