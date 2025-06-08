# frozen_string_literal: true

require 'active_support/core_ext/hash/slice'
require 'json-schema'
require 'json'
require 'rswag/specs/extended_schema'

module Rswag
  module Specs
    class RequestValidator
      def initialize(config = ::Rswag::Specs.config)
        @config = config
      end

      def validate!(metadata, request_payload)
        swagger_doc = @config.get_openapi_spec(metadata[:openapi_spec] || metadata[:swagger_doc])

        validate_body!(metadata, swagger_doc, request_payload)
      end

      private

      def validate_body!(metadata, swagger_doc, body)
        # Finding the first one for now, but need to see what happens if we
        # have more than one.
        body_parameter = metadata[:operation][:parameters].find { |p| p[:in] == :body }
        request_schema = body_parameter[:schema] if body_parameter

        return if request_schema.nil?

        version = @config.get_openapi_spec_version(metadata[:openapi_spec] || metadata[:swagger_doc])
        schemas = definitions_or_component_schemas(swagger_doc, version)

        validation_schema = request_schema
                            .merge('$schema' => 'http://tempuri.org/rswag/specs/extended_schema')
                            .merge(schemas)

        validation_options = validation_options_from(metadata)

        errors = JSON::Validator.fully_validate(validation_schema, body, validation_options)
        return unless errors.any?

        raise UnexpectedRequest,
              "Expected request body to match schema: #{errors.join("\n")}\n" \
              "Request body: #{JSON.pretty_generate(JSON.parse(body))}"
      end

      def validation_options_from(metadata)
        is_strict = @config.openapi_strict_schema_validation

        if metadata.key?(:swagger_strict_schema_validation)
          Rswag::Specs.deprecator.warn('Rswag::Specs: WARNING: This option will be removed in v3.0 please use openapi_all_properties_required and openapi_no_additional_properties set to true')
          is_strict = !!metadata[:swagger_strict_schema_validation]
        elsif metadata.key?(:openapi_strict_schema_validation)
          Rswag::Specs.deprecator.warn('Rswag::Specs: WARNING: This option will be removed in v3.0 please use openapi_all_properties_required and openapi_no_additional_properties set to true')
          is_strict = !!metadata[:openapi_strict_schema_validation]
        end

        all_properties_required = metadata.fetch(:openapi_all_properties_required,
                                                 @config.openapi_all_properties_required)
        no_additional_properties = metadata.fetch(:openapi_no_additional_properties,
                                                  @config.openapi_no_additional_properties)

        {
          strict: is_strict,
          allPropertiesRequired: all_properties_required,
          noAdditionalProperties: no_additional_properties
        }
      end

      def definitions_or_component_schemas(swagger_doc, version)
        if version.start_with?('2')
          swagger_doc.slice(:definitions)
        elsif swagger_doc.key?(:definitions) # Openapi3
          Rswag::Specs.deprecator.warn('Rswag::Specs: WARNING: definitions is replaced in OpenAPI3! Rename to components/schemas (in swagger_helper.rb)')
          swagger_doc.slice(:definitions)
        else
          components = swagger_doc[:components] || {}
          { components: components }
        end
      end
    end

    class UnexpectedRequest < StandardError; end
  end
end
