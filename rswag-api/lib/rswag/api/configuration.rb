module Rswag
  module Api
    class Configuration
      attr_accessor :openapi_root, :openapi_filter, :openapi_headers

      def resolve_openapi_root(env)
        path_params = env['action_dispatch.request.path_parameters'] || {}
        path_params[:openapi_root] || openapi_root
      end
    end
  end
end
