require 'open_api/rswag/api/middleware'

module OpenApi::Rswag
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace Rswag::Api

      initializer 'rswag-api.initialize' do |app|
        middleware.use Rswag::Api::Middleware, Rswag::Api.config
      end
    end
  end
end
