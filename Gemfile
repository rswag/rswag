# frozen_string_literal: true

source 'https://rubygems.org'

# Allow the rails version to come from an ENV setting so CI can test multiple versions.
# See http://www.schneems.com/post/50991826838/testing-against-multiple-rails-versions/
rails_version = Gem::Version.new(ENV['RAILS_VERSION'] || '8.0.0')

gem 'byebug'
gem 'puma'
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
  gem 'simplecov', '=0.21.2'
  gem 'test-unit'
end

group :development do
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
end

group :assets do
  gem 'uglifier'
end
