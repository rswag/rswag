module Rswag
  module Api
    class Configuration
      attr_accessor :swagger_root, :swagger_filter, :swagger_headers

      def resolve_swagger_root(env)
        path_params = env['action_dispatch.request.path_parameters'] || {}
        path_params[:swagger_root] || swagger_root
      end
    end
  end
end
