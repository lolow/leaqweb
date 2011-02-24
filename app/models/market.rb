class Market < ActiveRecord::Base
  #versioned :dependent => :tracking
  acts_as_taggable_on :sets
  acts_as_identifiable :prefix => "m"
  has_and_belongs_to_many :technologies
  has_many :parameter_values, :dependent => :delete_all
  scope :activated, tagged_with("MARKET")
  validates :name, :presence => true,
            :uniqueness => true,
            :format => {:with => /\A[a-zA-Z\d-]+\z/,
                        :message => "Please use only letters, numbers or '-' in name"}
end
