source 'http://rubygems.org'

gem 'rails', '3.2.2'

# Database wrappers
gem 'sqlite3'
gem 'mysql2'

# Rails 3.2 - JavaScript
gem 'execjs'
gem 'therubyracer' if RUBY_PLATFORM.downcase.include?("linux")
gem 'jquery-rails'

# HTML engine/template
gem 'haml'
gem 'simple_form'

# User identification
gem 'devise', '~> 2.0'
gem 'warden'

# Model extensions
gem 'acts-as-taggable-on', :git => 'https://github.com/mbleigh/acts-as-taggable-on'
gem 'will_paginate'
gem 'paper_trail'
gem 'daemons'
gem 'delayed_job_active_record'

# Backup + Template engine + State Machine
gem 'rubyzip', :require => 'zip/zip'
gem 'tenjin'
gem 'workflow'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails', " ~> 3.2.1"
  gem 'sass-rails', " ~> 3.2.3"
  gem 'uglifier', ">= 1.0.3"
end

# Remove extra log
gem 'quiet_assets', :group => :development

#test
group :test, :development do
  gem "rspec-rails", "~> 2.6"
end
group :test do
  gem "factory_girl_rails"
  gem "capybara"
  gem "guard-rspec"
  gem "faker"
end

