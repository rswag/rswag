require 'open_api/rswag/ui/middleware'

module OpenApi
  module Rswag
    module Ui
      class Engine < ::Rails::Engine
        isolate_namespace OpenApi::Rswag::Ui

        initializer 'rswag-ui.initialize' do |app|
          middleware.use OpenApi::Rswag::Ui::Middleware, OpenApi::Rswag::Ui.config
        end

        rake_tasks do
          load File.expand_path('../../../../tasks/rswag-ui_tasks.rake', __FILE__)
        end
      end
    end
  end
end
