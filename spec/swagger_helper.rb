require 'rails_helper'
require 'swagger_rails/rspec/dsl'

RSpec.configure do |config|
  # NOTE: Should be no need to modify these 3 lines
  config.add_setting :swagger_root
  config.add_setting :swagger_docs
  config.extend SwaggerRails::RSpec::DSL

  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the Swagger JSON middleware to serve API descriptions, you'll need
  # to ensure that the same folder is also specified in the swagger_rails initializer
  config.swagger_root = Rails.root.to_s + '/swagger'

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the "swaggerize" rake task, the complete Swagger will be generated
  # at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    'v1/swagger.json' => {
      swagger: '2.0',
      info: {
        title: 'API V1',
        version: 'v1'
      }
    }
  }
end
