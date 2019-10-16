require 'rspec/rails/swagger/route_parser'
require 'rails/generators'

module Rspec
  module Generators
    class SwaggerGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __FILE__)

      def setup
        @routes = RSpec::Rails::Swagger::RouteParser.new(controller_path).routes
      end

      def create_spec_file
        template 'spec.rb', File.join('spec/requests', "#{controller_path}_spec.rb")
      end

      private

      def controller_path
        file_path.chomp('_controller')
      end
    end
  end
end
