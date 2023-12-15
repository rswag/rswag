require 'rswag/ui/configuration'
require 'rswag/ui/engine'

module Rswag
  module Ui
    def self.configure
      yield(config)
    end

    def self.config
      @config ||= Configuration.new
    end

    def self.deprecator
      @deprecator ||= ActiveSupport::Deprecation.new('3.0', 'rswag-ui')
    end
  end
end
