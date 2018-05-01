unless Rails::Application.instance_methods.include?(:assets_manifest)
  warn <<-END
[Rswag] It seems you are using an api only rails setup, but Rswag
[Rswag] neeeds sprockets in order to work so its going to require it.
[Rswag] This might have undesired side effects, if thats not  the case
[Rswag] you can ignore this warning.
  END
  require 'sprockets/railtie'
end
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
