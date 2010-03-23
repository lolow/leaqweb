class Location < ActiveRecord::Base
  has_and_belongs_to_many :technologies

  def to_s
    self.name
  end
end
