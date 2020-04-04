# frozen_string_literal: true

require 'rack/auth/basic'

module Rswag
  module Ui
    # Extend Rack HTTP Basic Authentication, as per RFC 2617.
    # @api private
    #
    class BasicAuth < ::Rack::Auth::Basic
      def call(env)
        return @app.call(env) unless env_matching_path(env)

        super(env)
      end

      private

      def env_matching_path(env)
        path = base_path(env['PATH_INFO'])
        Rswag::Ui.config.config_object[:urls].find do |endpoint|
          base_path(endpoint[:url]) == path
        end
      end

      def base_path(url)
        url.downcase.split('/')[1]
      end
    end
  end
end
