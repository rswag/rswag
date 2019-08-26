source "https://rubygems.org"

# Allow the rails version to come from an ENV setting so Travis can test multiple versions.
# See http://www.schneems.com/post/50991826838/testing-against-multiple-rails-versions/
rails_version = ENV['RAILS_VERSION'] || '5.1.2'

rails_major_version = rails_version.split('.').first.to_i

gem 'rails', "#{rails_version}"

case rails_major_version
when 3
  gem 'strong_parameters'
else
  gem 'responders'
end

case rails_major_version
when 3..5
  gem 'sqlite3', '~> 1.3.6'
else
  gem 'sqlite3', '~> 1.4.1'
end

gem 'rswag-api', path: './rswag-api'
gem 'rswag-ui', path: './rswag-ui'

group :test do
  gem 'test-unit'
  gem 'rspec-rails'
  gem 'generator_spec'
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'rswag-specs', path: './rswag-specs'
end

group :assets do
  gem 'uglifier'
  gem 'therubyracer'
end

gem 'byebug'
gem 'puma'
