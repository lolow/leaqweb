class Aggregate < ActiveRecord::Base

  #Interfaces
  has_paper_trail
  acts_as_taggable_on :sets

  #Relations
  has_and_belongs_to_many :commodities
  has_many :parameter_values, :dependent => :delete_all

  #Validations
  validates :name, :presence => true,
            :uniqueness => true,
            :format => {:with => /\A[a-zA-Z\d-]+\z/,
                        :message => "Please use only letters, numbers or '-' in name"}

  #Scopes
  scope :activated, tagged_with("AGG")

end
