module Rswag
  module Models
    module Swaggerable
      extend ActiveSupport::Concern

      included do
        @swagger_custom_property_definitions = {}
      end

      class_methods do
        def swagger_definition(serializer_klass = "#{name}Serializer".constantize)
          serializer = serializer_klass.new(new)

          definition = {
            type: :object,
            required: swagger_required_attributes,
            properties: swagger_properties(serializer)
          }

          definition[:properties].merge!(@swagger_custom_property_definitions)
          definition
        end

        def swagger_attribute(attribute, type)
          @swagger_custom_property_definitions[attribute] = { type: type }
        end

        def swagger_properties(serializer)
          properties = {}

          serializer.attributes.keys.each do |key|
            properties[key] = { type: attribute_types[key.to_s].type }
          end

          swagger_model_associations_properties(serializer, properties)

          properties
        end

        def swagger_model_associations_properties(serializer, properties)
          serializer._reflections.each do |key, value|
            model = key.to_s.singularize.classify.constantize
            serializer = swagger_association_serializer(model, value.options)

            case value
            when ActiveModel::Serializer::HasManyReflection
              swagger_definition = { type: 'array', items: model.swagger_definition(serializer) }
            when ActiveModel::Serializer::BelongsToReflection
              swagger_definition = model.swagger_definition(serializer)
            end

            properties[key] = swagger_definition
          end

          properties
        end

        def swagger_association_serializer(model, options)
          return options[:serializer] if options.key?(:serializer)

          "#{model.name}Serializer".constantize
        end

        def swagger_required_attributes
          presence_validators = validators.select do |validator|
            validator.class == ActiveRecord::Validations::PresenceValidator
          end

          presence_validators.each_with_object([]) do |validator, required_attributes|
            required_attributes.concat(validator.attributes)
          end
        end
      end
    end
  end
end
