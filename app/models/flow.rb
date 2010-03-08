class Flow < ActiveRecord::Base
  has_and_belongs_to_many :technologies
end
