class Market < ActiveRecord::Base
  versioned
  acts_as_taggable_on :sets
  acts_as_identifiable :prefix => "m"
  has_and_belongs_to_many :technologies
  has_many :parameter_values, :dependent => :delete_all
  scope :activated, tagged_with("M")
end
