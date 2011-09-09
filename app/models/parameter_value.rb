class ParameterValue < ActiveRecord::Base

  has_paper_trail

  belongs_to :parameter
  belongs_to :technology
  belongs_to :commodity
  belongs_to :aggregate
  belongs_to :flow
  belongs_to :out_flow
  belongs_to :in_flow
  belongs_to :market
  belongs_to :sub_market, :class_name => "Market"
  belongs_to :scenario

  validates :value, :presence => true, :numericality => true
  validates :parameter, :presence => true
  validates :year, :numericality => {:only_integer => true, :minimum => -1}, :allow_nil => true
  validates :time_slice, :inclusion => {:in => %w(AN IN ID SN SD WN WD)}, :allow_nil => true
  validates :scenario, :presence => true

  scope :of, lambda { |names| joins(:parameter).where("parameters.name"=>names).order("parameters.name") }
  scope :technology, lambda { |tech| where(:technology_id=>tech) }

end