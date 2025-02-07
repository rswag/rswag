# frozen_string_literal: true

require 'json-schema'

module Rswag
  module Specs
    class ExtendedSchema < JSON::Schema::Draft4
      def initialize
        super
        @uri = URI.parse('http://tempuri.org/rswag/specs/extended_schema')
        @names = ['http://tempuri.org/rswag/specs/extended_schema']
      end

      def validate(current_schema, data, *)
        return if data.nil? && (current_schema.schema['nullable'] == true || current_schema.schema['x-nullable'] == true)

        super
      end
    end

    JSON::Validator.register_validator(ExtendedSchema.new)
  end
end
