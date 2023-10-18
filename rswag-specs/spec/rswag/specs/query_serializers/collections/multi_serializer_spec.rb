# frozen_string_literal: true

require 'rswag/specs/query_serializers/collections/multi_serializer'

module Rswag
  module Specs
    module QuerySerializers
      module Collections
        RSpec.describe MultiSerializer do
          describe "#serialize" do
            subject(:serialize) { described_class.new.serialize(name, value) }

            let(:name) { "values" }
            let(:value) { [123, 456] }

            it "serializes the name and value into multiple query parameters" do
              expect(serialize).to eq("values=123&values=456")
            end

            context "when value is empty" do
              let(:value) { [] }

              it "renders a blank string" do
                expect(serialize).to eq("")
              end
            end

            context "when name contains unescaped characters" do
              let(:name) { "the values" }

              it "escapes them" do
                expect(serialize).to eq("the+values=123&the+values=456")
              end
            end

            context "when value contains unescaped characters" do
              let(:value) { ["something cool", "neat"] }

              it "escapes them" do
                expect(serialize).to eq("values=something+cool&values=neat")
              end
            end
          end
        end
      end
    end
  end
end
