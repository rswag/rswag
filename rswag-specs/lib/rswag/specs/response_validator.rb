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

        validate_code!(metadata, response)
        validate_headers!(metadata, response.headers)
        validate_body!(metadata, swagger_doc, response.body)
      end

      private

      def validate_code!(metadata, response)
        expected = metadata[:response][:code].to_s
        if response.code != expected
          raise UnexpectedResponse,
                "Expected response code '#{response.code}' to match '#{expected}'\n" \
                "Response body: #{response.body}"
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

        components_schemas = {components: {schemas: swagger_doc[:components][:schemas]}}

        validation_schema = response_schema
          .merge('$schema' => 'http://tempuri.org/rswag/specs/extended_schema')
          .merge(components_schemas)
        
        errors = JSON::Validator.fully_validate(validation_schema, body)
        raise UnexpectedResponse, "Expected response body to match schema: #{errors[0]}" if errors.any?
      end
    end

    class UnexpectedResponse < StandardError; end
  end
end
