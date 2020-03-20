module Rswag
  module Ui
    class Middleware < Rack::Static

      def initialize(app, config)
        @config = config
        super(app, urls: [ '' ], root: config.assets_root )
      end

      def call(env)
        if base_path?(env)
          redirect_uri = env['SCRIPT_NAME'].chomp('/') + '/index.html'
          return [ 301, { 'Location' => redirect_uri }, [ ] ]
        end

        if index_path?(env)
          return [ 200, { 'Content-Type' => 'text/html' }, [ render_template ] ]
        end

        super
      end

      private

      def base_path?(env)
        env['REQUEST_METHOD'] == "GET" && env['PATH_INFO'] == "/"
      end

      def index_path?(env)
        env['REQUEST_METHOD'] == "GET" && env['PATH_INFO'] == "/index.html"
      end

      def render_template
        file = File.new(template_filename)
        template = ERB.new(file.read)
        template.result(@config.get_binding)
      end

      def template_filename
        @config.template_locations.find { |filename| File.exists?(filename) }
      end
    end
  end
end
