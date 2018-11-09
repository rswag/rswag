require 'json'
require 'rswag/specs/response_validator'

module Rswag
  module Specs

    describe ResponseValidator do
      subject { ResponseValidator.new(config) }

      before do
        allow(config).to receive(:get_swagger_doc).and_return(swagger_doc)
        allow(config).to(
          receive(:swagger_strict_schema_validation)
            .and_return(swagger_strict_schema_validation)
        )
      end
      let(:config) { double('config') }
      let(:swagger_doc) { {} }
      let(:swagger_strict_schema_validation) { nil }
      let(:example) { double('example') }
      let(:metadata) do
        {
          response: {
            code: 200,
            headers: { 'X-Rate-Limit-Limit' => { type: :integer } },
            schema: {
              type: :object,
              properties: { text: { type: :string } },
              required: [ 'text' ]
            }
          }
        }
      end

      describe '#validate!(metadata, response)' do
        let(:call) { subject.validate!(metadata, response) }
        let(:response) do
          OpenStruct.new(
            code: '200',
            headers: { 'X-Rate-Limit-Limit' => '10' },
            body: JSON.dump(text: "Some comment")
          )
        end

        context "response matches metadata" do
          it { expect { call }.to_not raise_error }
        end

        context "response code differs from metadata" do
          before { response.code = '400' }
          it { expect { call }.to raise_error /Expected response code/ }
        end

        context "response headers differ from metadata" do
          before { response.headers = {} }
          it { expect { call }.to raise_error /Expected response header/ }
        end

        context "when response body has missing properties" do
          before { response.body = JSON.dump(foo: "bar") }
          it { expect { call }.to raise_error /Expected response body/ }
        end

        context "when repsonse body has undefined properties" do
          before { response.body = JSON.dump(text: "text", foo: "bar") }

          context "with strict schema validation enabled" do
            let(:swagger_strict_schema_validation) { true }
            it { expect { call }.to raise_error /Expected response body/ }
          end

          context "with strict schema validation disabled" do
            let(:swagger_strict_schema_validation) { false }
            it { expect { call }.not_to raise_error }
          end

          context "with strict schema validation disabled in config but enabled in metadata" do
            let(:swagger_strict_schema_validation) { false }
            let(:metadata) { super().merge(swagger_strict_schema_validation: true) }

            it { expect { call }.to raise_error /Expected response body/ }
          end

          context "with strict schema validation enabled in config but disabled in metadata" do
            let(:swagger_strict_schema_validation) { true }
            let(:metadata) { super().merge(swagger_strict_schema_validation: false) }

            it { expect { call }.not_to raise_error }
          end
        end

        context 'referenced schemas' do
          before do
            swagger_doc[:definitions] = {
              'blog' => {
                type: :object,
                properties: { foo: { type: :string } },
                required: [ 'foo' ]
              }
            }
            metadata[:response][:schema] = { '$ref' => '#/definitions/blog' }
          end

          it 'uses the referenced schema to validate the response body' do
            expect { call }.to raise_error /Expected response body/
          end
        end
      end
    end
  end
end
