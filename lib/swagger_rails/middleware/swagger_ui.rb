module SwaggerRails
  class SwaggerUi < ActionDispatch::Static
    IGNORE_PATHS = [ '', '/', '/index.html' ]

    def call(env)
      # Serve index.html via swagger_ui_controller
      if IGNORE_PATHS.include?(env['PATH_INFO'])
        @app.call(env)
      else
        super(env)
      end
    end
  end
end
