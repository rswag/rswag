require "swagger_rails/engine"

module SwaggerRails

  def self.configure
    yield self
  end

  class << self
    attr_accessor :target_api_version

    #Defaults
    @@target_api_version = 'v1'
  end
end
