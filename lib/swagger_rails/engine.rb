require 'swagger_rails/middleware/swagger_json'
require 'swagger_rails/middleware/swagger_ui'

module SwaggerRails
  class Engine < ::Rails::Engine
    isolate_namespace SwaggerRails

    initializer 'swagger_rails.initialize' do |app|
      middleware.use SwaggerJson, SwaggerRails.config
      middleware.use SwaggerUi
    end
  end
end
