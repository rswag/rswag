# frozen_string_literal: true

require 'json-schema'

class OpenAPIOneOfAttribute < JSON::Schema::OneOfAttribute
  def self.validate(current_schema, data, fragments, processor, validator, options = {})
    return super unless current_schema.schema.key?('discriminator')

    discriminator = current_schema.schema['discriminator']
    prop_name = discriminator['propertyName']

    unless data.key?(prop_name)
      message = "The response payload must contain a property with name #{prop_name}"
      validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
      return
    end

    discriminator_value = data[prop_name]
    schema_ref = if discriminator['mapping']&.key?(discriminator_value)
      # Explicit schema matching using the ref specified by the discriminator mapping.
      schema_mapping = discriminator['mapping'][discriminator_value]
      current_schema.schema['oneOf'].find { |e| e['$ref'] == schema_mapping }
    else
      # Implicit schema matching using the discriminator value from the response data as schema name.
      { "$ref" => "#/components/schemas/#{discriminator_value}" }
    end

    unless schema_ref
      message = "The discriminator value #{discriminator_value} did not match any of the required schemas"
      validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
      return
    end

    original_data = data.is_a?(Hash) ? data.clone : data
    schema = JSON::Schema.new(schema_ref, current_schema.uri, validator)

    begin
      schema.validate(data, fragments, processor, options)
    rescue JSON::Schema::ValidationError
      data = original_data
      message = "The property '#{build_fragment(fragments)}' of type #{type_of_data(data)} did not match the required schema #{schema_ref}"
      validation_error(processor, message, fragments, current_schema, select, options[:record_errors])
    end
  end
end
