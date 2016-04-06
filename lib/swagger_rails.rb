require "swagger_rails/engine"

module SwaggerRails

  def self.configure
    yield self
  end

  class << self
    attr_accessor :doc_factories
    @@doc_factories = {}

    def swagger_doc(path, &block)
      @@doc_factories[path] = block 
    end

    def swagger_docs
      Hash[
        @@doc_factories.map do |path, factory|
          [ path, { swagger: '2.0' }.merge(factory.call) ]
        end
      ]
    end
  end
end
