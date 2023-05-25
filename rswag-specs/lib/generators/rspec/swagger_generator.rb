# frozen_string_literal: true

require 'rswag/route_parser'
require 'rails/generators'

module Rspec
  class SwaggerGenerator < ::Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)
    class_option :spec_path, type: :string, default: 'requests'

    def setup
      @routes = Rswag::RouteParser.new(controller_path).routes
    end

    def create_spec_file
      template 'spec.rb', File.join('spec', options['spec_path'], "#{controller_path}_spec.rb")
    end

    private

    def controller_path
      file_path.chomp('_controller')
    end
  end
end
