class Market < ActiveRecord::Base
  has_paper_trail
  acts_as_taggable_on :sets
  has_and_belongs_to_many :technologies
  has_many :parameter_values, :dependent => :delete_all
  scope :activated, tagged_with("MARKET")
  scope :matching_text, lambda {|text| where(['name LIKE ? OR description LIKE ?'] + ["%#{text}%"] * 2) }
  scope :matching_tag, lambda {|tag| tagged_with(tag) if (tag && tag!="" && tag != "null")}
  validates :name, :presence => true,
            :uniqueness => true,
            :format => {:with => /\A[a-zA-Z\d-]+\z/,
                        :message => "Please use only letters, numbers or '-' in name"}

  def parameter_values_for(parameters)
    ParameterValue.of(Array(parameters)).where(:market_id=>self).order(:year)
  end

end
