# frozen_string_literal: true

require 'rswag/api/configuration'
require 'rswag/api/engine'

module Rswag
  module Api
    def self.configure
      yield(config)
    end

    def self.config
      @config ||= Configuration.new
    end
  end
end
