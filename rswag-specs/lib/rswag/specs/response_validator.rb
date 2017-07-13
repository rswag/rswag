require 'active_support/core_ext/hash/slice'
require 'json-schema'
require 'json'
require 'rswag/specs/extended_schema'

module Rswag
  module Specs
    class ResponseValidator

      def initialize(config = ::Rswag::Specs.config)
        @config = config
      end

      def validate!(metadata, response, &block)
        swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])

        validate_code!(metadata, response.code)
        validate_headers!(metadata, response.headers)
        validate_body!(metadata, swagger_doc, response.body, &block)
        block.call(response) if block_given?
      end

      private

      def validate_code!(metadata, code)
        expected = metadata[:response][:code].to_s
        if code != expected
          raise UnexpectedResponse, "Expected response code '#{code}' to match '#{expected}'"
        end
      end

      def validate_headers!(metadata, headers)
        expected = (metadata[:response][:headers] || {}).keys
        expected.each do |name|
          raise UnexpectedResponse, "Expected response header #{name} to be present" if headers[name.to_s].nil?
        end
      end

      def validate_body!(metadata, swagger_doc, body)
        response_schema = metadata[:response][:schema]
        return if response_schema.nil?

        validation_schema = response_schema
          .merge('$schema' => 'http://tempuri.org/rswag/specs/extended_schema')
          .merge(swagger_doc.slice(:definitions))
        errors = JSON::Validator.fully_validate(validation_schema, body)
        raise UnexpectedResponse, "Expected response body to match schema: #{errors[0]}" if errors.any?
      end
    end

    class UnexpectedResponse < StandardError; end
  end
end
