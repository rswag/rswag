# frozen_string_literal: true

require 'rswag/specs/request_factory'
require 'rswag/specs/response_validator'
require 'rswag/specs/request_validator'

module Rswag
  module Specs
    module ExampleHelpers
      def submit_request(metadata)
        request = RequestFactory.new(metadata, self).build_request

        RequestValidator.new.validate!(metadata, request[:payload]) if (200..299).include? metadata[:response][:code]

        send(
          request[:verb],
          request[:path],
          params: request[:payload],
          headers: request[:headers]
        )
      end

      def assert_response_matches_metadata(metadata)
        ResponseValidator.new.validate!(metadata, response)
      end
    end
  end
end
