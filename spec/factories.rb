require 'faker'

Factory.define :admin, :class => User do |f|
  f.email "admin@domain.com"
  f.password  "password"
  f.confirmed_at Time.now
end

Factory.define :commodity, :class => Commodity do |f|
  f.sequence(:name) { |n| "COM-#{n}" }
  f.description { Faker::Lorem.words(3) }
  f.set_list "C"
end

Factory.define :demand, :parent => :commodity do |f|
  f.sequence(:name) { |n| "DEMAND-#{n}" }
  f.set_list "C,DEM"
end

Factory.define :fuel, :parent => :commodity do |f|
  f.sequence(:name) { |n| "ENERGY-#{n}" }
  f.set_list "C,ENC,IMP"
end

Factory.define :pollutant, :parent => :commodity do |f|
  f.sequence(:name) { |n| "POLLUTANT#{n}" }
  f.set_list "C,POLL"
end

Factory.define :demand_device, :class => Technology do |f|
  f.sequence(:name) { |n| "TECHNOLOGY#{n}" }
  f.description { Faker::Lorem.words(3) }
  f.set_list "P,DMD"
end

Factory.define :energy_system, :class => EnergySystem do |f|
  f.sequence(:name) { |n| "RES#{n}" }
  f.description { Faker::Lorem.words(3) }
  f.nb_periods {1 + rand(5)}
  f.period_duration {1 + rand(5)}
  f.first_year  {2000 + rand(12)}
end

Factory.define :demand_driver, :class => DemandDriver do |f|
  f.sequence(:name) { |n| "DEMANDDRIVER#{n}" }
  f.description { Faker::Lorem.words(3) }
end

Factory.define :combustion, :class => Combustion do |f|
  f.sequence(:fuel) { |n| "FUEL-#{n}" }
  f.sequence(:pollutant) { |n| "POLL-#{n}" }
  f.value 1
  f.source { Faker::Lorem.words(3) }
end

Factory.define :technology_set, :class => TechnologySet do |f|
  f.sequence(:name) { |n| "TECHNOLOGY-SET-#{n}" }
  f.description { Faker::Lorem.words(3) }
end

Factory.define :commodity_set, :class => CommoditySet do |f|
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



