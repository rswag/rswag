require 'rails/generators'

module SwaggerRails

  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def add_swagger_json
      template('swagger.json', 'config/swagger/v1/swagger.json')
    end

    def add_initializer
      template('swagger_rails.rb', 'config/initializers/swagger_rails.rb')
    end
  end
end
