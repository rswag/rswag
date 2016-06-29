require 'swagger_rails/version'
require 'swagger_rails/configuration'

module SwaggerRails

  def self.configure
    yield(config)
  end

  def self.config
    @config ||= Configuration.new
  end
end

require 'swagger_rails/engine' if defined?(Rails)
