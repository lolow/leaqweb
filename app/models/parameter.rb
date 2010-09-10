class Parameter < ActiveRecord::Base

  versioned

  has_many :parameter_values

  validates_presence_of :name
  validates_uniqueness_of :name
  
  def to_s
    self.name
  end
end
