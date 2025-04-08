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

        openapi = parse_file(filename)
        @config.openapi_filter&.call(openapi, env)
        mime = Rack::Mime.mime_type(::File.extname(env['PATH_INFO']), 'text/plain')
        headers = { 'Content-Type' => mime }.merge(@config.openapi_headers || {})
        body = unload_openapi(filename, openapi)

        ['200', headers, [body]]
      end

      private

      def parse_file(filename)
        if /\.ya?ml$/.match?(filename)
          load_yaml(filename)
        else
          load_json(filename)
        end
      end

      def load_yaml(filename)
        YAML.safe_load(File.read(filename))
      end

      def load_json(filename)
        JSON.parse(File.read(filename))
      end

      def unload_openapi(filename, openapi)
        if /\.ya?ml$/.match?(filename)
          YAML.dump(openapi)
        else
          JSON.dump(openapi)
        end
      end
    end
  end
end
