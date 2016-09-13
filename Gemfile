source 'https://rubygems.org'

# Declare your gem's dependencies in swagger_rails.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'debugger', group: [:development, :test]
#
gem 'sqlite3'

# Allow the rails version to come from an ENV setting so Tavis can test multiple
# versions. Inspired by http://www.schneems.com/post/50991826838/testing-against-multiple-rails-versions/
def rails_version
  ENV['RAILS_VERSION'] || '3.2.22'
end

group :development, :test do
  gem 'pry'
  gem 'generator_spec'

  gem 'rails', "~> #{rails_version}"

  case rails_version.split('.').first
  when '3'
    gem 'strong_parameters'
  when '4', '5'
    gem 'responders'
  end
end

group :test do
  gem 'test-unit'
  gem 'database_cleaner'
end
