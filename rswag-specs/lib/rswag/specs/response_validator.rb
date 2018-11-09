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

      def validate!(metadata, response)
        swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])

        validate_code!(metadata, response.code)
        validate_headers!(metadata, response.headers)
        validate_body!(metadata, swagger_doc, response.body)
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

        validation_options = prepare_validation_options(metadata)

        errors = JSON::Validator.fully_validate(validation_schema, body, validation_options)
        raise UnexpectedResponse, "Expected response body to match schema: #{errors[0]}" if errors.any?
      end

      def prepare_validation_options(metadata)
        is_strict = !!metadata.fetch(
          :swagger_strict_schema_validation,
          @config.swagger_strict_schema_validation
        )

        { strict: is_strict }
      end
    end

    class UnexpectedResponse < StandardError; end
  end
end
