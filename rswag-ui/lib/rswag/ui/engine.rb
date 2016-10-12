module Rswag
  module Ui
    class Engine < ::Rails::Engine
      isolate_namespace Rswag::Ui

      initializer 'rswag-ui.initialize' do |app|
        if app.config.respond_to?(:assets)
          app.config.assets.precompile += [ 'swagger-ui/*' ]
        end
      end
    end
  end
end
