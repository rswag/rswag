require 'swagger_rails/middleware/swagger_docs'
require 'swagger_rails/middleware/swagger_ui'

module SwaggerRails
  class Engine < ::Rails::Engine
    isolate_namespace SwaggerRails

    initializer 'swagger_rails.initialize' do |app|
      middleware.use SwaggerDocs, SwaggerRails.config.swagger_dir_string
      middleware.use SwaggerUi, "#{root}/bower_components/swagger-ui/dist"
    end
  end
end
