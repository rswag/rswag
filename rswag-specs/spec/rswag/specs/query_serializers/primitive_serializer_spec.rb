# frozen_string_literal: true

require 'rswag/specs/query_serializers/primitive_serializer'

module Rswag
  module Specs
    module QuerySerializers
      RSpec.describe PrimitiveSerializer do
        describe "#serialize" do
          subject(:serialize) { described_class.new.serialize(name, value) }

          let(:name) { "value" }
          let(:value) { 123_456 }

          it "serializes the name and value into a query parameter" do
            expect(serialize).to eq("value=123456")
          end

          context "when name contains unescaped characters" do
            let(:name) { "the value" }

            it "escapes them" do
              expect(serialize).to eq("the+value=123456")
            end
          end

          context "when value contains unescaped characters" do
            let(:value) { "something cool" }

            it "escapes them" do
              expect(serialize).to eq("value=something+cool")
            end
          end
        end
      end
    end
  end
end
