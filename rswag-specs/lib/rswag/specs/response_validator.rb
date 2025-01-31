# frozen_string_literal: true

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
        openapi_spec = @config.get_openapi_spec(metadata[:openapi_spec])

        validate_code!(metadata, response)
        validate_headers!(metadata, response.headers)
        validate_body!(metadata, openapi_spec, response.body)
      end

      private

      def validate_code!(metadata, response)
        expected = metadata[:response][:code].to_s
        return unless response.code != expected

        raise UnexpectedResponse,
              "Expected response code '#{response.code}' to match '#{expected}'\n" \
                "Response body: #{response.body}"
      end

      def validate_headers!(metadata, headers)
        header_schemas = metadata[:response][:headers] || {}
        expected = header_schemas.keys
        expected.each do |name|
          nullable_attribute = header_schemas.dig(name.to_s, :schema, :nullable)
          required_attribute = header_schemas.dig(name.to_s, :required)

          is_nullable = nullable_attribute.nil? ? false : nullable_attribute
          is_required = required_attribute.nil? ? true : required_attribute

          if !headers.include?(name.to_s) && is_required
            raise UnexpectedResponse, "Expected response header #{name} to be present"
          end

          if headers.include?(name.to_s) && headers[name.to_s].nil? && !is_nullable
            raise UnexpectedResponse, "Expected response header #{name} to not be null"
          end
        end
      end

      def validate_body!(metadata, openapi_spec, body)
        response_schema = metadata[:response][:schema]
        return if response_schema.nil?

        schemas = { components: openapi_spec[:components] }

        validation_schema = response_schema
                            .merge('$schema' => 'http://tempuri.org/rswag/specs/extended_schema')
                            .merge(schemas)

        validation_options = validation_options_from(metadata)

        errors = JSON::Validator.fully_validate(validation_schema, body, validation_options)
        return unless errors.any?

        raise UnexpectedResponse,
              "Expected response body to match schema: #{errors.join("\n")}\n" \
              "Response body: #{JSON.pretty_generate(JSON.parse(body))}"
      end

      def validation_options_from(metadata)
        all_properties_required = metadata.fetch(:openapi_all_properties_required, @config.openapi_all_properties_required)
        no_additional_properties = metadata.fetch(:openapi_no_additional_properties, @config.openapi_no_additional_properties)

        {
          allPropertiesRequired: all_properties_required,
          noAdditionalProperties: no_additional_properties
        }
      end
    end

    class UnexpectedResponse < StandardError; end
  end
end
