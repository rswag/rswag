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
        path = env['PATH_INFO']
        # Sanitize the filename for directory traversal by expanding, and ensuring
        # its starts with the root directory.
        filename = File.expand_path(File.join(@config.resolve_openapi_root(env), path))
        unless filename.start_with? @config.resolve_openapi_root(env).to_s
          return @app.call(env)
        end

        if env['REQUEST_METHOD'] == 'GET' && File.file?(filename)
          openapi = parse_file(filename)
          @config.openapi_filter.call(openapi, env) unless @config.openapi_filter.nil?
          mime = Rack::Mime.mime_type(::File.extname(path), 'text/plain')
          headers = { 'Content-Type' => mime }.merge(@config.openapi_headers || {})
          body = unload_openapi(filename, openapi)

          return [
            '200',
            headers,
            [ body ]
          ]
        end

        return @app.call(env)
      end

      private

      def parse_file(filename)
        if /\.ya?ml$/ === filename
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
        if /\.ya?ml$/ === filename
          YAML.dump(openapi)
        else
          JSON.dump(openapi)
        end
      end
    end
  end
end
