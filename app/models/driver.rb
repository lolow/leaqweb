class Driver < ActiveRecord::Base
  belongs_to :commodity
  has_many :driver_values
end
