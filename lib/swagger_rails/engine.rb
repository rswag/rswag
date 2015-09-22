require 'swagger_rails/middleware/swagger_ui'

module SwaggerRails
  class Engine < ::Rails::Engine
    isolate_namespace SwaggerRails

    middleware.use SwaggerUi, "#{root}/bower_components/swagger-ui/dist"
  end
end
