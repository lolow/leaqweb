# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:

#Create admin user
admin = User.create(:email => "admin@domain.com", :password => "password")
admin.confirm!

#Create base scenario
Scenario.create(:name=>"BASE")

#Default parameter
require 'yaml'
filename = File.join(Rails.root,'lib','etem','parameters.yml')
File.open(filename) do |f|
  YAML::load(f).each do |record|
    Parameter.create(record)
  end
end
