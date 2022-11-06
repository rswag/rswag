# frozen_string_literal: true

require 'simplecov'

RSpec.configure do |_config|
  SimpleCov.start do
    enable_coverage :branch
    primary_coverage :branch
    filters.clear
    add_filter %r{^/spec/}
  end
end
