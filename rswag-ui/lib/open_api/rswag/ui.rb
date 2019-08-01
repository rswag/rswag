require 'open_api/rswag/ui/configuration'
require 'open_api/rswag/ui/engine'

module OpenApi
  module Rswag
    module Ui
      def self.configure
        yield(config)
      end

      def self.config
        @config ||= Configuration.new
      end
    end
  end
end
