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
          return [ 200, { 'Content-Type' => 'text/html', 'Content-Security-Policy' => csp }, [ render_template ] ]
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
        @config.template_locations.find { |filename| File.exist?(filename) }
      end

      def csp
        <<~POLICY.gsub "\n", ' '
          default-src 'self';
          img-src 'self' data:;
          font-src 'self' https://fonts.gstatic.com;
          style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
          script-src 'self' 'unsafe-inline';
        POLICY
      end
    end
  end
end
