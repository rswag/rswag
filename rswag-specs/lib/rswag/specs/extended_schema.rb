# frozen_string_literal: true

require 'json-schema'

module Rswag
  module Specs
    class ResponseRequiredAttribute < JSON::Schema::RequiredAttribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        return super unless data.is_a?(Hash)

        filtered_schema = remove_write_only_required_properties(current_schema, validator)

        super(filtered_schema, data, fragments, processor, validator, options)
      end

      # For response validation, OpenAPI says `writeOnly` properties are not required.
      # This method removes those properties from the required list for validation
      private_class_method def self.remove_write_only_required_properties(current_schema, validator)
        filtered_required = current_schema.schema['required'].reject do |property|
          property_schema = current_schema.schema.fetch('properties', {})[property.to_s]
          property_schema.is_a?(Hash) && property_schema['writeOnly'] == true
        end

        return current_schema if filtered_required == current_schema.schema['required']

        JSON::Schema.new(
          current_schema.schema.merge('required' => filtered_required),
          current_schema.uri,
          validator
        )
      end
    end

    class ResponsePropertiesV4Attribute < JSON::Schema::PropertiesV4Attribute
      # This hook only runs when requiredness comes from `allPropertiesRequired: true`.
      # It does not handle an explicit `required: [...]` array; that case is handled by
      # ResponseRequiredAttribute above.
      #
      # Example handled here:
      #   schema:
      #     type: object
      #     properties:
      #       password:
      #         type: string
      #         writeOnly: true
      #
      #   options:
      #     allPropertiesRequired: true
      #
      # Draft 4 would treat `password` as required because every property becomes
      # required. For response validation, OpenAPI says `writeOnly` properties stay
      # optional, so this returns false for that property.
      def self.required?(schema, options)
        super && schema['writeOnly'] != true
      end
    end

    class ExtendedSchema < JSON::Schema::Draft4
      def initialize
        super
        @uri = URI.parse('http://tempuri.org/rswag/specs/extended_schema')
        @names = ['http://tempuri.org/rswag/specs/extended_schema']
        @attributes['properties'] = ResponsePropertiesV4Attribute
        @attributes['required'] = ResponseRequiredAttribute
      end

      def validate(current_schema, data, *)
        if data.nil? && (current_schema.schema['nullable'] == true || current_schema.schema['x-nullable'] == true)
          return
        end

        super
      end
    end

    JSON::Validator.register_validator(ExtendedSchema.new)
  end
end
