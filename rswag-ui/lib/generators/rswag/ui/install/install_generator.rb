require 'rails/generators'

module Rswag
  module Ui

    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def add_initializer
        template('rswag-ui.rb', 'config/initializers/rswag-ui.rb')
      end

      def add_routes
        route("mount Rswag::Ui::Engine => '/api-docs'")
      end
    end
  end
end
