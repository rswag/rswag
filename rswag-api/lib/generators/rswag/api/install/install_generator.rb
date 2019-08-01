require 'rails/generators'

module Rswag
  module Api

    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def add_initializer
        template('rswag_api.rb', 'config/initializers/rswag_api.rb')
      end

      def add_routes
        route("mount Rswag::Api::Engine => '/api-docs'")
      end
    end
  end
end
