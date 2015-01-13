require 'haml-rails'
require 'coffee-rails'

module SwaggerRails
  class Engine < ::Rails::Engine
    isolate_namespace SwaggerRails
  end
end
