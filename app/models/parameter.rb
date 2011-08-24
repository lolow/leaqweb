class Parameter < ActiveRecord::Base

  has_paper_trail

  has_many :parameter_values

  validates :name, :presence => true, :uniqueness => true

  scope :named, lambda {|name| where(:name=>name)}
  scope :matching_text, lambda {|text| where(['name LIKE ? OR definition LIKE ?'] + ["%#{text}%"] * 2) }
  scope :matching_tag

  def to_s
    name
  end

  def parameter_values_for(parameters)
    parameter_values.order(:year)
  end

end