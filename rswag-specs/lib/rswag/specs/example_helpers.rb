require 'rswag/specs/request_factory'
require 'rswag/specs/response_validator'

module Rswag
  module Specs
    module ExampleHelpers

      def submit_request(api_metadata)
        factory = RequestFactory.new(api_metadata, config.get_swagger_doc(api_metadata[:swagger_doc]))

        if RAILS_VERSION < 5
          send(
            api_metadata[:operation][:verb],
            factory.build_fullpath(self),
            factory.build_body(self),
            factory.build_headers(self)
          )
        else
          send(
            api_metadata[:operation][:verb],
            factory.build_fullpath(self),
            {
              params: factory.build_body(self),
              headers: factory.build_headers(self)
            }
          )
        end
      end

      def assert_response_matches_metadata(api_metadata)
        validator = ResponseValidator.new(api_metadata, config.get_swagger_doc(api_metadata[:swagger_doc]))
        validator.validate!(response)
      end

      private

      def config
        ::Rswag::Specs.config
      end
    end
  end
end
