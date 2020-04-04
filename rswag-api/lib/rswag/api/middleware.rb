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
        filename = "#{@config.resolve_swagger_root(env)}/#{path}"

        if env['REQUEST_METHOD'] == 'GET' && File.file?(filename)
          swagger = parse_file(filename)
          @config.swagger_filter.call(swagger, env) unless @config.swagger_filter.nil?
          mime = Rack::Mime.mime_type(::File.extname(path), 'text/plain')
          headers = { 'Content-Type' => mime }.merge(@config.swagger_headers || {})
          body = unload_swagger(filename, swagger)

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

      def unload_swagger(filename, swagger)
        if /\.ya?ml$/ === filename
          YAML.dump(swagger)
        else
          JSON.dump(swagger)
        end
      end
    end
  end
end
