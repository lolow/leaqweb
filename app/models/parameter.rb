class Parameter < ActiveRecord::Base
  has_many :parameter_values
  
  def to_s
    self.name
  end
end
