class DriverValue < ActiveRecord::Base
  belongs_to :driver
  validates_presence_of :value
  validates_numericality_of :value
end
