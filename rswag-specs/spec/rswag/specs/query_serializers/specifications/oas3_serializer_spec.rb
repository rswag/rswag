# frozen_string_literal: true

require 'rswag/specs/query_serializers/specifications/oas3_serializer'

module Rswag
  module Specs
    module QuerySerializers
      module Specifications
        RSpec.describe OAS3Serializer do
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

            let(:param) { { schema: { type: type } } }
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

            let(:param) do
              {
                name: name,
                style: style,
                explode: explode,
                schema: { type: :array }
              }
            end

            let(:name) { "some_random_name_#{rand(1..1_000)}" }
            let(:style) { nil }
            let(:value) { ["raw_value_#{rand(1..1_000)}", "raw_value_#{rand(1..1_000)}"] }

            context "when explode is unspecified" do
              let(:explode) { nil }

              it_behaves_like "it serializes the array", described_class::MULTI_SERIALIZER
            end

            context "when explode is true" do
              let(:explode) { true }

              it_behaves_like "it serializes the array", described_class::MULTI_SERIALIZER
            end

            context "when explode is false" do
              let(:explode) { false }

              it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS[:form]

              context "when style is form" do
                let(:style) { :form }

                it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS[:form]
              end

              context "when style is spaceDelimited" do
                let(:style) { :spaceDelimited }

                it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS.fetch(:spaceDelimited)
              end

              context "when style is pipeDelimited" do
                let(:style) { :pipeDelimited }

                it_behaves_like "it serializes the array", described_class::COLLECTION_SERIALIZERS.fetch(:pipeDelimited)
              end
            end
          end

          describe "#serialize_object" do
            subject(:serialize_object) { described_class.new(param).serialize_object(value) }

            let(:param) do
              {
                name: name,
                style: style,
                explode: explode,
                schema: { type: :array }
              }
            end

            let(:name) { "some_random_name_#{rand(1..1_000)}" }
            let(:style) { nil }
            let(:explode) { nil }
            let(:value) { { one: "raw_value_#{rand(1..1_000)}", two: "raw_value_#{rand(1..1_000)}" } }

            context "when style is something invalid" do
              let(:style) { :somethingInvalid }

              # I don't know if this is intentional behavior or if this is just
              # a quirk of how serialization was initially implemented.
              it "returns nil" do
                expect(serialize_object).to be_nil
              end
            end

            context "when style is deepObject" do
              let(:style) { :deepObject }

              it "uses ActiveSupport's #to_query method on the name and value" do
                expect(serialize_object).to eq({ name => value }.to_query)
              end
            end

            context "when style is form" do
              let(:style) { :form }

              context "when explode is true" do
                let(:explode) { true }

                it "uses ActiveSupport's #to_query method on the value" do
                  expect(serialize_object).to eq(value.to_query)
                end
              end

              context "when explode is false" do
                let(:explode) { false }
                let(:serializer) { described_class::COLLECTION_SERIALIZERS[:form] }
                let(:serialized_value) { "something_random_#{rand(1..1_000)}" }

                before do
                  allow(serializer).to receive(:serialize).and_return(serialized_value)
                end

                it "serializes the flattened parameter with the form serializer" do
                  serialize_object
                  expect(serializer).to have_received(:serialize).with(name, value.to_a.flatten)
                end

                it "returns the value from the form serializer" do
                  expect(serialize_object).to eq(serialized_value)
                end
              end
            end
          end

          describe "#serialize_primitive" do
            subject(:serialize_primitive) { described_class.new(param).serialize_primitive(value) }

            let(:param) { { name: name, schema: { type: :string } } }
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
