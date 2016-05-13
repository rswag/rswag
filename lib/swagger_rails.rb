require "swagger_rails/engine"

module SwaggerRails

  class Configuration
    attr_reader :swagger_docs, :swagger_dir_string

    def initialize
      @swagger_docs = {}
      @swagger_dir_string = nil
    end

    def swagger_doc(path, doc)
      @swagger_docs[path] = doc
    end

    def swagger_dir(dir_string)
      @swagger_dir_string = dir_string
    end
  end

  class << self
    attr_reader :config

    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end
  end
end
