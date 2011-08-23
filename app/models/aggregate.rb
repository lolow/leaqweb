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
  scope :matching_text, lambda {|text| where(['name LIKE ? OR description LIKE ?'] + ["%#{text}%"] * 2) }
  scope :matching_tag, lambda {|tag| tagged_with(tag) if (tag && tag!="" && tag != "null")}

  def parameter_values_for(parameters)
    ParameterValue.of(Array(parameters)).where(:aggregate_id=>self).order(:year)
  end

end
