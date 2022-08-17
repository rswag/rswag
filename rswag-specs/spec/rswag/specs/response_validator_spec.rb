# frozen_string_literal: true

require 'rswag/specs/response_validator'

module Rswag
  module Specs
    RSpec.describe ResponseValidator do
      subject { ResponseValidator.new(config) }

      before do
        allow(config).to receive(:get_swagger_doc).and_return(swagger_doc)
        allow(config).to receive(:get_swagger_doc_version).and_return('2.0')
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
              properties: {
                text: { type: :string },
                number: { type: :integer }
              },
              required: ['text', 'number']
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
            body: '{"text":"Some comment", "number": 3}'
          )
        end

        context 'response matches metadata' do
          it { expect { call }.to_not raise_error }
        end

        context 'response code differs from metadata' do
          before { response.code = '400' }
          it { expect { call }.to raise_error(/Expected response code/) }
        end

        context 'response headers differ from metadata' do
          before { response.headers = {} }
          it { expect { call }.to raise_error(/Expected response header/) }
        end

        context 'response body differs from metadata' do
          before { response.body = '{"foo":"Some comment"}' }
          it { expect { call }.to raise_error(/Expected response body/) }
        end

        context 'referenced schemas' do
          context 'swagger 2.0' do
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
              expect { call }.to raise_error(/Expected response body/)
            end
          end

          context 'openapi 3.0.1' do
            context 'components/schemas' do
              before do
                allow(ActiveSupport::Deprecation).to receive(:warn)
                allow(config).to receive(:get_swagger_doc_version).and_return('3.0.1')
                swagger_doc[:components] = {
                  schemas: {
                    'blog' => {
                      type: :object,
                      properties: { foo: { type: :string } },
                      required: ['foo']
                    }
                  }
                }
                metadata[:response][:schema] = { '$ref' => '#/components/schemas/blog' }
              end

              it 'uses the referenced schema to validate the response body' do
                expect { call }.to raise_error(/Expected response body/)
              end

              context 'nullable referenced schema' do
                let(:response) do
                  OpenStruct.new(
                    code: '200',
                    headers: { 'X-Rate-Limit-Limit' => '10' },
                    body: '{ "blog": null }'
                  )
                end

                before do
                  metadata[:response][:schema] = {
                    properties: { blog: { '$ref' => '#/components/schema/blog' } },
                    required: ['blog']
                  }
                end

                context 'using x-nullable attribute' do
                  before do
                    metadata[:response][:schema][:properties][:blog]['x-nullable'] = true
                  end

                  context 'response matches metadata' do
                    it { expect { call }.to_not raise_error }
                  end
                end

                context 'using nullable attribute' do
                  before do
                    metadata[:response][:schema][:properties][:blog]['nullable'] = true
                  end

                  context 'response matches metadata' do
                    it { expect { call }.to_not raise_error }
                  end
                end
              end

              context 'nullable oneOf wtih referenced schema' do
                let(:response) do
                  OpenStruct.new(
                    code: '200',
                    headers: { 'X-Rate-Limit-Limit' => '10' },
                    body: '{ "blog": null }'
                  )
                end

                before do
                  metadata[:response][:schema] = {
                    properties: {
                      blog: {
                        oneOf: [{ '$ref' => '#/components/schema/blog' }]
                      }
                    },
                    required: ['blog']
                  }
                end

                context 'using x-nullable attribute' do
                  before do
                    metadata[:response][:schema][:properties][:blog]['x-nullable'] = true
                  end

                  context 'response matches metadata' do
                    it { expect { call }.to_not raise_error }
                  end
                end

                context 'using nullable attribute' do
                  before do
                    metadata[:response][:schema][:properties][:blog]['nullable'] = true
                  end

                  context 'response matches metadata' do
                    it { expect { call }.to_not raise_error }
                  end
                end
              end
            end

            context 'deprecated definitions' do
              before do
                allow(ActiveSupport::Deprecation).to receive(:warn)
                allow(config).to receive(:get_swagger_doc_version).and_return('3.0.1')
                swagger_doc[:definitions] = {
                  'blog' => {
                    type: :object,
                    properties: { foo: { type: :string } },
                    required: ['foo']
                  }
                }
                metadata[:response][:schema] = { '$ref' => '#/definitions/blog' }
              end

              it 'warns the user to upgrade' do
                expect { call }.to raise_error(/Expected response body/)
                expect(ActiveSupport::Deprecation).to have_received(:warn)
                  .with('Rswag::Specs: WARNING: definitions is replaced in OpenAPI3! Rename to components/schemas (in swagger_helper.rb)')
              end
            end
          end
        end
      end
    end
  end
end
