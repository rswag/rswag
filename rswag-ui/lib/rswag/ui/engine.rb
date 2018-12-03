require 'rswag/ui/middleware'

class UiBasicAuth < ::Rack::Auth::Basic
  def call(env)
    return @app.call(env) unless env_matching_path

    super(env)
  end

  private

  def env_matching_path
    swagger_endpoints = Rswag::Ui.config.swagger_endpoints[:urls]
    swagger_endpoints.find do |endpoint|
      base_path = base_path(endpoint[:url])
      env_base_path = base_path(env['PATH_INFO'])

      base_path == env_base_path
    end
  end

  def base_path(url)
    url.downcase.split('/')[1]
  end
end

module Rswag
  module Ui
    class Engine < ::Rails::Engine
      isolate_namespace Rswag::Ui

      initializer 'rswag-ui.initialize' do |app|
        middleware.use Rswag::Ui::Middleware, Rswag::Ui.config

        if Rswag::Ui.config.basic_auth_enabled
          c = Rswag::Ui.config
          app.middleware.use UiBasicAuth do |username, password|
            c.config_object[:basic_auth].values == [username, password]
          end
        end
      end

      rake_tasks do
        load File.expand_path('../../../tasks/rswag-ui_tasks.rake', __FILE__)
      end
    end
  end
end
