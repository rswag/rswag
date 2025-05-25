# frozen_string_literal: true

require 'rails/generators'

module Rswag
  module Specs
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def add_openapi_helper
        template('openapi_helper.rb', 'spec/openapi_helper.rb')
      end
    end
  end
end
