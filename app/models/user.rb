class User < ActiveRecord::Base

  acts_as_audited :except => [:password, :password_confirmation, :email]

  devise :registerable, :database_authenticatable, :confirmable, :recoverable,
         :rememberable, :trackable, :validatable

  attr_accessible :email, :password, :password_confirmation
  
end