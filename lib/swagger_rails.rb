require "swagger_rails/engine"

module SwaggerRails

  def self.configure
    yield self
  end

  class << self
    attr_accessor :swagger_docs

    #Defaults
    @@swagger_docs = {
      'V1' => '/swagger/v1/swagger.json'
    }
  end
end
