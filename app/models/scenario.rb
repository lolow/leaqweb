class Scenario < ActiveRecord::Base
  has_many :parameter_values, :dependent => :delete_all

  scope :matching_text, lambda {|text| where(['name LIKE ?'] + ["%#{text}%"]) }
  scope :matching_tag

  before_destroy :reject_if_base

  #Validations
  validates :name, :presence => true,
            :uniqueness => true,
            :format => {:with => /\A[a-zA-Z\d]+\z/,
                        :message => "Please use only letters or numbers in name"}


  def self.base
    Scenario.where(:name=>"BASE").find(:first)
  end

  private

  def reject_if_base
    raise "Cannot destroy BASE scenario" if name=="BASE"
  end

end
