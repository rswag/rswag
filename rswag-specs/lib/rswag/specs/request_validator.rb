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
        openapi_spec = @config.get_openapi_spec(metadata[:openapi_spec])

        validate_body!(metadata, openapi_spec, request_payload)
      end

      private

      def validate_body!(metadata, openapi_spec, body)
        # Finding the first one for now, but need to see what happens if we
        # have more than one.
        body_parameter = metadata[:operation][:parameters].find { |p| p[:in] == :body }
        request_schema = body_parameter[:schema] if body_parameter

        return if request_schema.nil?

        schemas = { components: openapi_spec[:components] }

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
        all_properties_required = metadata.fetch(:openapi_all_properties_required,
                                                 @config.openapi_all_properties_required)
        no_additional_properties = metadata.fetch(:openapi_no_additional_properties,
                                                  @config.openapi_no_additional_properties)

        {
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
