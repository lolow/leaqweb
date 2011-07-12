# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:

#Create admin user
admin = User.create(:email => "admin@domain.com", :password => "password")
admin.confirm!

#Create base scenario
Scenario.create(:id=>1,:name=>"BASE")