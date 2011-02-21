class Aggregation < ActiveRecord::Base
  belongs_to :aggregate, :class_name => "Commodity"
  belongs_to :component, :class_name => "Commodity"
end
