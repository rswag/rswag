# frozen_string_literal: true

require 'active_support/core_ext/hash/conversions'
require_relative '../collections/multi_serializer'
require_relative '../collections/xsv_serializer'
require_relative '../primitive_serializer'

module Rswag
  module Specs
    module QuerySerializers
      module Specifications
        # OAS 3: https://swagger.io/docs/specification/serialization/
        class OAS3Serializer
          # Maps a style to the corresponding serializer. Uses the CSV separator
          # by default.
          COLLECTION_SERIALIZERS = Hash.new(
            Collections::XSVSerializer.new(','),
          ).merge(
            spaceDelimited: Collections::XSVSerializer.new('%20'),
            pipeDelimited: Collections::XSVSerializer.new('|')
          ).freeze

          # Holds a multi serializer instance to avoid allocating objects with
          # each instance / invocation.
          MULTI_SERIALIZER = Collections::MultiSerializer.new

          # Maps a type to a method that can serialize it. The
          # `serialize_primitive` method is the default.
          SERIALIZER_METHOD = Hash.new(
            :serialize_primitive
          ).merge(
            array: :serialize_array,
            object: :serialize_object
          ).freeze

          def initialize(param)
            @name = param[:name]
            @style = param[:style]&.to_sym
            @explode = param[:explode].nil? ? true : param[:explode]
            @type = param[:schema][:type]&.to_sym
          end

          attr_reader :name, :style, :explode, :type

          def serialize(value)
            method = SERIALIZER_METHOD[type]
            send(method, value)
          end

          def serialize_array(value)
            return MULTI_SERIALIZER.serialize(name, value.to_a.flatten) if explode

            serializer = COLLECTION_SERIALIZERS[style]
            serializer.serialize(name, value.to_a.flatten)
          end

          def serialize_object(value)
            case style
            when :deepObject
              return { name => value }.to_query
            when :form
              if explode
                return value.to_query
              else
                serializer = COLLECTION_SERIALIZERS[:form]
                return serializer.serialize(name, value.to_a.flatten)
              end
            end
          end

          def serialize_primitive(value)
            PrimitiveSerializer.new.serialize(name, value)
          end
        end
      end
    end
  end
end
