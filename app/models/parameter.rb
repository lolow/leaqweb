class Parameter < ActiveRecord::Base

  PARAMETERS =

  versioned

  has_many :parameter_values

  validates :name, :presence => true, :uniqueness => true
  
  def to_s
    name
  end
  
end
