# frozen_string_literal: true

require 'rswag/specs/query_serializers/specifications/swagger_serializer'

module Rswag
  module Specs
    module QuerySerializers
      module Specifications
        RSpec.describe SwaggerSerializer do
          describe "#serialize" do
            subject(:serializer) { described_class.new(param) }

            shared_examples "it serializes" do |method|
              let(:return_value) { "serialized_value_#{rand(0..1_000)}" }

              before { allow(serializer).to receive(method).and_return(return_value) }

              it "calls the appropriate serializer method" do
                serializer.serialize(value)

                expect(serializer).to have_received(method).with(value)
              end

              it "returns the value from the appropriate serializer method" do
                expect(serializer.serialize(value)).to eq(return_value)
              end
            end

            let(:param) { { type: type } }
            let(:type) { [:integer, :date, :string, :float].sample }
            let(:value) { "raw_value_#{rand(1..1_000)}" }

            it_behaves_like "it serializes", :serialize_primitive

            context "when type is array" do
              let(:type) { :array }

              it_behaves_like "it serializes", :serialize_array
            end

            context "when type is object" do
              let(:type) { :object }

              it_behaves_like "it serializes", :serialize_object
            end
          end

          describe "#serialize_array" do
            subject(:serialize_array) { described_class.new(param).serialize_array(value) }

            shared_examples "it serializes the array" do |serializer|
              let(:serialized_value) { "anything_#{rand(1..1_000)}" }

              before do
                allow(serializer).to receive(:serialize).and_return(serialized_value)
              end

              it "passes the name and value to the serializer" do
                serialize_array
                expect(serializer).to have_received(:serialize).with(name, value)
              end

              it "returns the value from the serializer" do
                expect(serialize_array).to eq(serialized_value)
              end
            end

            let(:param) { { name: name, collectionFormat: collection_format } }
            let(:name) { "some_random_name_#{rand(1..1_000)}" }
            let(:collection_format) { nil }
            let(:value) { "raw_value_#{rand(1..1_000)}" }

            it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS[:csv]

            context "when collectionFormat is csv" do
              let(:collection_format) { :csv }

              it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS[:csv]
            end

            context "when collectionFormat is ssv" do
              let(:collection_format) { :ssv }

              it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS.fetch(:ssv)
            end

            context "when collectionFormat is tsv" do
              let(:collection_format) { :tsv }

              it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS.fetch(:tsv)
            end

            context "when collectionFormat is pipes" do
              let(:collection_format) { :pipes }

              it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS.fetch(:pipes)
            end

            context "when collectionFormat is multi" do
              let(:collection_format) { :multi }

              it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS.fetch(:multi)
            end
          end

          describe "#serialize_object" do
            subject(:serialize_object) { described_class.new(param).serialize_object(value) }

            let(:param) { { name: name } }
            let(:name) { "some_random_name_#{rand(1..1_000)}" }
            let(:value) { "raw_value_#{rand(1..1_000)}" }

            let(:primitive_double) { instance_double(PrimitiveSerializer) }
            let(:serialized_value) { "anything_#{rand(1..1_000)}" }

            before do
              allow(PrimitiveSerializer).to receive(:new).and_return(primitive_double)
              allow(primitive_double).to receive(:serialize).and_return(serialized_value)
            end

            it "passes the name and value to the primitive serializer" do
              serialize_object
              expect(primitive_double).to have_received(:serialize).with(name, value)
            end

            it "returns the value from the primitive serializer" do
              expect(serialize_object).to eq(serialized_value)
            end
          end

          describe "#serialize_primitive" do
            subject(:serialize_primitive) { described_class.new(param).serialize_primitive(value) }

            let(:param) { { name: name } }
            let(:name) { "some_random_name_#{rand(1..1_000)}" }
            let(:value) { "raw_value_#{rand(1..1_000)}" }

            let(:primitive_double) { instance_double(PrimitiveSerializer) }
            let(:serialized_value) { "anything_#{rand(1..1_000)}" }

            before do
              allow(PrimitiveSerializer).to receive(:new).and_return(primitive_double)
              allow(primitive_double).to receive(:serialize).and_return(serialized_value)
            end

            it "passes the name and value to the primitive serializer" do
              serialize_primitive
              expect(primitive_double).to have_received(:serialize).with(name, value)
            end

            it "returns the value from the primitive serializer" do
              expect(serialize_primitive).to eq(serialized_value)
            end
          end
        end
      end
    end
  end
end
