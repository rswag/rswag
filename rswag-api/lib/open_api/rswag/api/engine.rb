require 'open_api/rswag/api/middleware'

module OpenApi
  module Rswag
    module Api
      class Engine < ::Rails::Engine
        isolate_namespace OpenApi::Rswag::Api

        initializer 'rswag-api.initialize' do |app|
          middleware.use OpenApi::Rswag::Api::Middleware, OpenApi::Rswag::Api.config
        end
      end
    end
  end
end
