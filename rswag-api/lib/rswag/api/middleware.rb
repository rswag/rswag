require 'json'

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
          swagger = load_json(filename)
          @config.swagger_filter.call(swagger, env) unless @config.swagger_filter.nil?

          return [
            '200',
            { 'Content-Type' => 'application/json' },
            [ JSON.dump(swagger) ]
          ]
        end
          
        return @app.call(env)
      end

      private

      def load_json(filename)
        JSON.parse(File.read(filename))
      end
    end
  end
end
