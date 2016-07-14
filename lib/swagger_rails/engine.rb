require 'swagger_rails/middleware/swagger_json'

module SwaggerRails
  class Engine < ::Rails::Engine
    isolate_namespace SwaggerRails

    initializer 'swagger_rails.initialize' do |app|
      middleware.use SwaggerJson, SwaggerRails.config
    end
  end
end
