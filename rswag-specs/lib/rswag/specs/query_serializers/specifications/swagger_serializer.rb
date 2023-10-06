# frozen_string_literal: true

require_relative '../collections/multi_serializer'
require_relative '../collections/xsv_serializer'
require_relative '../primitive_serializer'

module Rswag
  module Specs
    module QuerySerializers
      module Specifications
        class SwaggerSerializer
          # Maps a collection format to the corresponding serializer. CSV is the
          # default.
          COLLECTION_SERIALIZERS = Hash.new(
            Collections::XSVSerializer.new(',')
          ).merge(
            ssv: Collections::XSVSerializer.new(' '),
            tsv: Collections::XSVSerializer.new('\t'),
            pipes: Collections::XSVSerializer.new('|'),
            multi: Collections::MultiSerializer.new
          ).freeze

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
            @type = (param[:type] || param.dig(:schema, :type))&.to_sym
            @collection_format = param[:collectionFormat]
          end

          attr_reader :name, :type, :collection_format

          def serialize(value)
            method = SERIALIZER_METHOD[type]
            send(method, value)
          end

          def serialize_array(value)
            serializer = COLLECTION_SERIALIZERS[collection_format]
            serializer.serialize(name, value)
          end

          def serialize_object(value)
            serialize_primitive(value)
          end

          def serialize_primitive(value)
            PrimitiveSerializer.new.serialize(name, value)
          end
        end
      end
    end
  end
end
