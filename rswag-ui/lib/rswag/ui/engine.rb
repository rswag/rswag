module Rswag
  module Ui
    class Engine < ::Rails::Engine
      isolate_namespace Rswag::Ui

      initializer 'rswag-ui.initialize' do |app|
        if app.config.respond_to?(:assets)
          app.config.assets.precompile += [
            'swagger-ui/css/*',
            'swagger-ui/fonts/*',
            'swagger-ui/images/*',
            'swagger-ui/lang/*',
            'swagger-ui/lib/*',
            'swagger-ui/swagger-ui.min.js'
          ]
        end
      end
    end
  end
end
