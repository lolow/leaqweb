# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:


#Create admin user
admin = User.create!(:email => "admin@domain.com", :password => "adminpass")
admin.confirm!

#Create standard user
user = User.create!(:email => "leaq", :password => "leaq")
user.confirm!