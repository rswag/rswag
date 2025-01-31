# frozen_string_literal: true

require 'rswag/api/middleware'

module Rswag
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace Rswag::Api

      initializer 'rswag-api.initialize' do |_app|
        middleware.use Rswag::Api::Middleware, Rswag::Api.config
      end
    end
  end
end
