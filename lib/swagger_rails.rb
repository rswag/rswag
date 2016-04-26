require "swagger_rails/engine"

module SwaggerRails

  def self.configure
    yield self
  end

  class << self
    @@swagger_docs = {}

    def swagger_doc(path, &block)
      @@swagger_docs[path] = block
    end

    def swagger_docs
      Hash[
        @@swagger_docs.map do |path, factory|
          [ path, factory.call.merge(swagger: '2.0') ]
        end
      ]
    end
  end
end
