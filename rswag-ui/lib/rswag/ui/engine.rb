# frozen_string_literal: true

require "rswag/ui/middleware"

module Rswag
  module Ui
    class Engine < ::Rails::Engine
      isolate_namespace Rswag::Ui

      initializer "rswag-ui.initialize" do |_app|
        middleware.use Rswag::Ui::Middleware, Rswag::Ui.config
      end

      rake_tasks do
        load File.expand_path("../../tasks/rswag-ui_tasks.rake", __dir__)
      end
    end
  end
end
