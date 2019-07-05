# frozen_string_literal: true

require 'rswag/specs/response_validator'

module Rswag
  module Specs
    describe ResponseValidator do
      subject { ResponseValidator.new(config) }

      before do
        allow(config).to receive(:get_swagger_doc).and_return(swagger_doc)
      end
      let(:config) { double('config') }
      let(:swagger_doc) { {} }
      let(:example) { double('example') }
      let(:metadata) do
        {
          response: {
            code: 200,
            headers: { 'X-Rate-Limit-Limit' => { type: :integer } },
            schema: {
              type: :object,
              properties: { text: { type: :string } },
              required: ['text']
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
            body: '{"text":"Some comment"}'
          )
        end

        context 'response matches metadata' do
          it { expect { call }.to_not raise_error }
        end

        context 'response code differs from metadata' do
          before { response.code = '400' }
          it { expect { call }.to raise_error /Expected response code/ }
        end

        context 'response headers differ from metadata' do
          before { response.headers = {} }
          it { expect { call }.to raise_error /Expected response header/ }
        end

        context 'response body differs from metadata' do
          before { response.body = '{"foo":"Some comment"}' }
          it { expect { call }.to raise_error /Expected response body/ }
        end

        context 'referenced schemas' do
          before do
            swagger_doc[:definitions] = {
              'blog' => {
                type: :object,
                properties: { foo: { type: :string } },
                required: ['foo']
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
