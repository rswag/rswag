module OpenApi
  
end
require 'open_api/rswag/api/configuration'
require 'open_api/rswag/api/engine'

module OpenApi
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
end
