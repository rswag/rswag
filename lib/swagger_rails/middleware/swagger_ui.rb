module SwaggerRails
  class SwaggerUi < Rack::Static

    def initialize(app)
      options = {
        root: File.expand_path('../../../../bower_components/swagger-ui/dist', __FILE__),
        urls: %w(/css /fonts /images /lang /lib /oc2.html /swagger-ui.js)
      }
      # NOTE: /index.html is excluded as it is servered dynamically (via conrtoller)
      super(app, options)
    end
  end
end
