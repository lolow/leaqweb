class Aggregate < ActiveRecord::Base
  has_paper_trail
  acts_as_taggable_on :sets
  has_and_belongs_to_many :commodities
  has_many :parameter_values, :dependent => :delete_all
  scope :activated, tagged_with("AGG")
  validates :name, :presence => true,
            :uniqueness => true,
            :format => {:with => /\A[a-zA-Z\d-]+\z/,
                        :message => "Please use only letters, numbers or '-' in name"}
  def pid
    name
  end
end
