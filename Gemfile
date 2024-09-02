# frozen_string_literal: true

source 'https://rubygems.org'

# Allow the rails version to come from an ENV setting so CI can test multiple versions.
# See http://www.schneems.com/post/50991826838/testing-against-multiple-rails-versions/
rails_version = Gem::Version.new(ENV['RAILS_VERSION'] || '7.2.0')

gem 'rails', rails_version.to_s

gem 'responders'

if rails_version >= Gem::Version.new('7.2.0')
  gem 'sqlite3'
else
  gem 'sqlite3', '~> 1.4.1'
end

gem 'net-smtp', require: false
gem 'rswag-api', path: './rswag-api'
gem 'rswag-ui', path: './rswag-ui'

group :development, :test do
  gem 'rswag-specs', path: './rswag-specs'
end

group :test do
  gem 'capybara'
  gem 'climate_control'
  gem 'geckodriver-helper'
  gem 'generator_spec'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'test-unit'
  gem 'simplecov', '=0.21.2'
end

group :development do
  gem 'rubocop'
end

group :assets do
  gem 'mini_racer'
  gem 'uglifier'
end

gem 'byebug'
gem 'puma'
