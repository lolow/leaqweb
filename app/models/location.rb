class Location < ActiveRecord::Base
  has_and_belongs_to_many :technologies

  validates_uniqueness_of :name
  validates_presence_of :name
  validates_format_of :name, :with => /\A[a-zA-Z\d-]+\z/,  :message => "Please use only regular letters, numbers or symbol '-' in name"

  acts_as_identifiable :prefix => "l"

  def to_s
    self.name
  end
end
