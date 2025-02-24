# frozen_string_literal: true

require 'json'
require 'yaml'
require 'rack/mime'

module Rswag
  module Api
    class Middleware
      def initialize(app, config)
        @app = app
        @config = config
      end

      def call(env)
        # Sanitize the filename for directory traversal by expanding, and ensuring
        # its starts with the root directory.
        openapi_root = @config.resolve_openapi_root(env)
        filename = File.expand_path(File.join(openapi_root, env['PATH_INFO']))
        return @app.call(env) unless filename.start_with? openapi_root.to_s
        return @app.call(env) unless env['REQUEST_METHOD'] == 'GET' && File.file?(filename)

        body = with_config_file(filename) do |openapi|
          @config.openapi_filter&.call(openapi, env)
        end
        mime = Rack::Mime.mime_type(::File.extname(env['PATH_INFO']), 'text/plain')
        headers = { 'Content-Type' => mime }.merge(@config.openapi_headers || {})

        ['200', headers, [body]]
      end

      private

      def with_config_file(filename)
        is_yaml = /\.ya?ml$/.match?(filename)
        file = File.read(filename)
        config = is_yaml ? YAML.safe_load(file) : JSON.parse(file)
        yield(config)
        is_yaml ? YAML.dump(config) : JSON.dump(config)
      end
    end
  end
end
