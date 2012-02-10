require 'faker'

Factory.define :admin, :class => User do |f|
  f.email "admin@domain.com"
  f.password  "password"
  f.confirmed_at Time.now
end

Factory.define :demand, :class => Commodity do |f|
  f.sequence(:name) { |n| "DEMAND#{n}-" }
  f.description { Faker::Lorem.words(3) }
  f.set_list "C,DEM"
end

Factory.define :fuel, :class => Commodity do |f|
  f.sequence(:name) { |n| "ENERGY#{n}-" }
  f.description { Faker::Lorem.words(3) }
  f.set_list "C,ENC,IMP"
end

Factory.define :pollutant, :class => Commodity do |f|
  f.sequence(:name) { |n| "POLLUTANT#{n}" }
  f.description { Faker::Lorem.words(3) }
  f.set_list "C,POLL"
end

Factory.define :demand_device, :class => Technology do |f|
  f.sequence(:name) { |n| "TECHNOLOGY#{n}" }
  f.description { Faker::Lorem.words(3) }
  f.set_list "P,DMD"
end

Factory.define :demand_driver do |f|
  f.sequence(:name) { |n| "DEMANDDRIVER#{n}" }
  f.definition { Faker::Lorem.words(3) }
end

Factory.define :combustion do |f|
  f.fuel
  f.pollutant
  f.value 1
  f.source { Faker::Lorem.words(3) }
end

Factory.define :technology_set do |f|
  f.sequence(:name) { |n| "TECHNOLOGY_SET#{n}" }
  f.description { Faker::Lorem.words(3) }
end

Factory.define :commodity_set do |f|
  f.sequence(:name) { |n| "COMMODITY-SET-#{n}" }
  f.description { Faker::Lorem.words(3) }
end

Factory.define :scenario do |f|
  f.sequence(:name) { |n| "SCENARIO#{n}" }
end

Factory.define :result_set do |f|
  f.sequence(:name) { |n| "RESULT SET #{n}:" + Faker::Lorem.words(3).to_s }
end

Factory.define :stored_query do |f|
  f.sequence(:name) { |n| "STORED QUERY #{n}:" + Faker::Lorem.words(3).to_s }
  f.display StoredQuery::DISPLAY.first
end



