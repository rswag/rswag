require 'rswag/specs/request_factory'
require 'rswag/specs/response_validator'

module Rswag
  module Specs
    module ExampleHelpers

      def submit_request(metadata)
        request = RequestFactory.new.build_request(metadata, self)

        if RAILS_VERSION < 5
          send(
            request[:verb],
            request[:path],
            request[:body],
            rackify_headers(request[:headers]) # Rails test infrastructure requires Rack headers
          )
        else
          send(
            request[:verb],
            request[:path],
            {
              params: request[:body],
              headers: request[:headers]
            }
          )
        end
      end

      def assert_response_matches_metadata(metadata, &block)
        ResponseValidator.new.validate!(metadata, response, &block)
      end

      private

      def rackify_headers(headers)
        name_value_pairs = headers.map do |name, value|
          [
            case name
              when 'Accept' then 'HTTP_ACCEPT'
              when 'Content-Type' then 'CONTENT_TYPE'
              when 'Authorization' then 'HTTP_AUTHORIZATION'
              else name
            end,
            value
          ]
        end

        Hash[ name_value_pairs ]
      end
    end
  end
end
