module Rswag
  module Api
    class Configuration
      attr_accessor :openapi_root, :swagger_filter, :swagger_headers

      def resolve_openapi_root(env)
        path_params = env['action_dispatch.request.path_parameters'] || {}

        if path_params.key?(:swagger_root)
          Rswag::Api.deprecator.warn(
            'swagger_root is deprecated and will be removed from rswag-api 3.0 (use openapi_root instead)'
          )
          return path_params[:swagger_root]
        end

        path_params[:openapi_root] || openapi_root
      end
    end
  end
end
