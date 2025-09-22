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
  end
end
