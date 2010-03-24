class Location < ActiveRecord::Base
  has_and_belongs_to_many :technologies

  validates_uniqueness_of :name
  validates_presence_of :name
  validates_format_of  :name , :with => /^[A-Za-z_0-9]*\z/, :message => "Cannot contain White Space"

  def to_s
    self.name
  end
end
