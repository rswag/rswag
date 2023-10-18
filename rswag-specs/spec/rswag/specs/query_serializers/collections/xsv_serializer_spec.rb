# frozen_string_literal: true

require 'rswag/specs/query_serializers/collections/xsv_serializer'

module Rswag
  module Specs
    module QuerySerializers
      module Collections
        RSpec.describe XSVSerializer do
          describe "#serialize" do
            subject(:serialize) { described_class.new(sep).serialize(name, value) }

            let(:sep) { "," }
            let(:name) { "values" }
            let(:value) { [123, 456] }

            it "serializes the name and value into a delimited query parameter" do
              expect(serialize).to eq("values=123,456")
            end

            context "when value is empty" do
              let(:value) { [] }

              it "renders a query parameter with a blank value" do
                expect(serialize).to eq("values=")
              end
            end

            context "when name contains unescaped characters" do
              let(:name) { "the values" }

              it "escapes them" do
                expect(serialize).to eq("the+values=123,456")
              end
            end

            context "when value contains unescaped characters" do
              let(:value) { ["something cool", "neat"] }

              it "escapes them" do
                expect(serialize).to eq("values=something+cool,neat")
              end
            end

            context "when initialized with a separator" do
              let(:sep) { "<?>" }

              it "uses the separator to delimit the values" do
                expect(serialize).to eq("values=123<?>456")
              end
            end
          end
        end
      end
    end
  end
end
