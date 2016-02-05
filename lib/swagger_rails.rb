require "swagger_rails/engine"

module SwaggerRails

  def self.configure
    yield self
  end

  class << self
    attr_accessor :swagger_docs

    @@swagger_docs = {
      'V1' => 'v1/swagger.json'
    }
  end
end
