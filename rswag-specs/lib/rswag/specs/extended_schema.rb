require 'json-schema'

module Rswag
  module Specs
    class ExtendedSchema < JSON::Schema::Validator

      def initialize
        super
        extend_schema_definition("http://json-schema.org/draft-04/schema#")
        @attributes['type'] = ExtendedTypeAttribute
        @uri = URI.parse('http://tempuri.org/rswag/specs/extended_schema')
      end
    end

    class ExtendedTypeAttribute < JSON::Schema::TypeV4Attribute

      def self.validate(current_schema, data, fragments, processor, validator, options={})
        return if data.nil? && current_schema.schema['x-nullable'] == true
        super
      end
    end

    JSON::Validator.register_validator(ExtendedSchema.new)
  end
end
