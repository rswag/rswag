# frozen_string_literal: true

source 'https://rubygems.org'

# Allow the rails version to come from an ENV setting so Travis can test multiple versions.
# See http://www.schneems.com/post/50991826838/testing-against-multiple-rails-versions/
rails_version = ENV['RAILS_VERSION'] || '5.2.6'

gem 'rails', rails_version.to_s

gem 'responders'

case rails_version.split('.').first
when '5'
  gem 'sqlite3', '~> 1.3.6'
when  '6', '7'
  gem 'sqlite3', '~> 1.4.1'
end

case RUBY_VERSION.split('.').first
when '3'
  gem 'net-smtp', require: false
end

gem 'rswag-api', path: './rswag-api'
gem 'rswag-ui', path: './rswag-ui'

group :development, :test do
  gem 'rswag-specs', path: './rswag-specs'
end

group :test do
  gem 'capybara'
  gem 'geckodriver-helper'
  gem 'generator_spec'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'test-unit'
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
