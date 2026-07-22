# frozen_string_literal: true

require 'rswag/specs/request_factory'
require 'rswag/specs/response_validator'
require 'rswag/specs/request_validator'

module Rswag
  module Specs
    module ExampleHelpers
      def submit_request(metadata, config = ::Rswag::Specs.config)
        request = RequestFactory.new(metadata, self).build_request

        validate_request_body = metadata.fetch(:validate_request_body,
                                               config.validate_request_body)
        if (200..299).cover?(metadata[:response][:code]) && validate_request_body
          RequestValidator.new.validate!(metadata, request[:payload])
        end

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
