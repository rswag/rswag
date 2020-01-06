# frozen_string_literal: true

require 'rack/auth/basic'

module Rswag
  module Ui
    # Extend Rack HTTP Basic Authentication, as per RFC 2617.
    # @api private
    #
    class BasicAuth < ::Rack::Auth::Basic
      def call(env)
        return @app.call(env) unless env_matching_path

        super(env)
      end

      private

      def env_matching_path
        Rswag::Ui.config.swagger_endpoints[:urls].find do |endpoint|
          base_path(endpoint[:url]) == env_base_path
        end
      end

      def env_base_path
        base_path(env['PATH_INFO'])
      end

      def base_path(url)
        url.downcase.split('/')[1]
      end
    end
  end
end
