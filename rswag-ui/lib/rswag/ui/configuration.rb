require 'ostruct'
require 'rack'

module Rswag
  module Ui
    class Configuration
      attr_reader :template_locations
      attr_accessor :basic_auth_enabled
      attr_accessor :config_object
      attr_accessor :oauth_config_object
      attr_reader :assets_root

      def initialize
        @template_locations = [
          # preferred override location
          "#{Rack::Directory.new('').root}/swagger/index.erb",
          # backwards compatible override location
          "#{Rack::Directory.new('').root}/app/views/rswag/ui/home/index.html.erb",
          # default location
          File.expand_path('../index.erb', __FILE__)
        ]
        @assets_root = File.expand_path('../../../../node_modules/swagger-ui-dist', __FILE__)
        @config_object = {}
        @oauth_config_object = {}
        @basic_auth_enabled = false
      end

      def swagger_endpoint(url, name)
        @config_object[:urls] ||= []
        @config_object[:urls] << { url: url, name: name }
      end

      def basic_auth_credentials(username, password)
        @config_object[:basic_auth] = { username: username, password: password }
      end

      # rubocop:disable Naming/AccessorMethodName
      def get_binding
        binding
      end
      # rubocop:enable Naming/AccessorMethodName
    end
  end
end
