# frozen_string_literal: true

require 'rswag/specs/response_validator'

module Rswag
  module Specs
    Response = Struct.new(:code, :headers, :body, keyword_init: true)

    RSpec.describe ResponseValidator do
      subject { ResponseValidator.new(config) }

      before do
        allow(config).to receive(:get_openapi_spec).and_return(openapi_spec)
        allow(config).to receive(:openapi_all_properties_required).and_return(openapi_all_properties_required)
        allow(config).to receive(:openapi_no_additional_properties).and_return(openapi_no_additional_properties)
      end

      let(:config) { double('config') }
      let(:openapi_spec) { {} }
      let(:example) { double('example') }
      let(:openapi_all_properties_required) { false }
      let(:openapi_no_additional_properties) { false }
      let(:schema) do
        {
          type: :object,
          properties: {
            text: { type: :string },
            number: { type: :integer }
          },
          required: %w[text number]
        }
      end

      let(:metadata) do
        {
          response: {
            code: 200,
            headers: {
              'X-Rate-Limit-Limit' => { type: :integer },
              'X-Cursor' => {
                schema: {
                  type: :string
                },
                required: false
              },
              'X-Per-Page' => {
                schema: {
                  type: :string,
                  nullable: true
                }
              }
            },
            schema: { **schema }
          }
        }
      end

      shared_context 'with strict deprecation warning' do
        before do
          allow(Rswag::Specs.deprecator).to receive(:warn)
        end

        after do
          expect(Rswag::Specs.deprecator)
            .to have_received(:warn).with('Rswag::Specs: WARNING: This option will be removed in v3.0' \
                                          ' please use openapi_all_properties_required' \
                                          ' and openapi_no_additional_properties set to true')
        end
      end

      describe '#validate!(metadata, response)' do
        let(:call) { subject.validate!(metadata, response) }
        let(:response) do
          Response.new(
            code: '200',
            headers: {
              'X-Rate-Limit-Limit' => '10',
              'X-Cursor' => 'test_cursor',
              'X-Per-Page' => 25
            },
            body: '{"text":"Some comment", "number": 3}'
          )
        end

        context 'response matches metadata' do
          it { expect { call }.not_to raise_error }
        end

        context 'response code differs from metadata' do
          before { response.code = '400' }

          it { expect { call }.to raise_error(/Expected response code/) }
        end

        context 'response headers differ from metadata' do
          before { response.headers = {} }

          it { expect { call }.to raise_error(/Expected response header/) }
        end

        context 'response headers do not include optional header' do
          before do
            response.headers = {
              'X-Rate-Limit-Limit' => '10',
              'X-Per-Page' => 25
            }
          end

          it { expect { call }.not_to raise_error }
        end

        context 'response headers include nullable header' do
          before do
            response.headers = {
              'X-Rate-Limit-Limit' => '10',
              'X-Cursor' => 'test_cursor',
              'X-Per-Page' => nil
            }
          end

          it { expect { call }.not_to raise_error }
        end

        context 'response headers missing nullable header' do
          before do
            response.headers = {
              'X-Rate-Limit-Limit' => '10',
              'X-Cursor' => 'test_cursor'
            }
          end

          it { expect { call }.to raise_error(/Expected response header/) }
        end

        context 'response body differs from metadata' do
          before { response.body = '{"foo":"Some comment"}' }

          it { expect { call }.to raise_error(/Expected response body/) }
        end

        context 'when response body does not have additional properties and missing properties' do
          context 'with all properties required enabled' do
            let(:openapi_all_properties_required) { true }

            it { expect { call }.not_to raise_error }
          end

          context 'with all properties required disabled' do
            let(:openapi_all_properties_required) { false }

            it { expect { call }.not_to raise_error }
          end

          context 'with all properties required disabled in config but enabled in metadata' do
            let(:openapi_all_properties_required) { false }
            let(:metadata) { super().merge(openapi_all_properties_required: true) }

            it { expect { call }.not_to raise_error }
          end

          context 'with all properties required enabled in config but disabled in metadata' do
            let(:openapi_all_properties_required) { true }
            let(:metadata) { super().merge(openapi_all_properties_required: false) }

            it { expect { call }.not_to raise_error }
          end

          context 'with no additional properties enabled' do
            let(:openapi_no_additional_properties) { true }

            it { expect { call }.not_to raise_error }
          end

          context 'with no additional properties disabled' do
            let(:openapi_no_additional_properties) { false }

            it { expect { call }.not_to raise_error }
          end

          context 'with no additional properties validation disabled in config but enabled in metadata' do
            let(:openapi_no_additional_properties) { false }
            let(:metadata) { super().merge(openapi_no_additional_properties: true) }

            it { expect { call }.not_to raise_error }
          end

          context 'with no additional properties validation enabled in config but disabled in metadata' do
            let(:openapi_no_additional_properties) { true }
            let(:metadata) { super().merge(openapi_no_additional_properties: false) }

            it { expect { call }.not_to raise_error }
          end

          context 'when schema does not have required property' do
            let(:schema) do
              {
                type: :object,
                properties: {
                  text: { type: :string },
                  number: { type: :integer }
                }
              }
            end

            context 'with all properties required enabled' do
              let(:openapi_all_properties_required) { true }

              it { expect { call }.not_to raise_error }
            end

            context 'with all properties required disabled' do
              let(:openapi_all_properties_required) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with all properties required disabled in config but enabled in metadata' do
              let(:openapi_all_properties_required) { false }
              let(:metadata) { super().merge(openapi_all_properties_required: true) }

              it { expect { call }.not_to raise_error }
            end

            context 'with all properties required enabled in config but disabled in metadata' do
              let(:openapi_all_properties_required) { true }
              let(:metadata) { super().merge(openapi_all_properties_required: false) }

              it { expect { call }.not_to raise_error }
            end

            context 'with no additional properties enabled' do
              let(:openapi_no_additional_properties) { true }

              it { expect { call }.not_to raise_error }
            end

            context 'with no additional properties disabled' do
              let(:openapi_no_additional_properties) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with no additional properties validation disabled in config but enabled in metadata' do
              let(:openapi_no_additional_properties) { false }
              let(:metadata) { super().merge(openapi_no_additional_properties: true) }

              it { expect { call }.not_to raise_error }
            end

            context 'with no additional properties validation enabled in config but disabled in metadata' do
              let(:openapi_no_additional_properties) { true }
              let(:metadata) { super().merge(openapi_no_additional_properties: false) }

              it { expect { call }.not_to raise_error }
            end
          end
        end

        context 'when response body has additional properties' do
          before { response.body = '{"foo":"Some comment", "number": 3, "text":"bar"}' }

          context 'with all properties required enabled' do
            let(:openapi_all_properties_required) { true }

            it { expect { call }.not_to raise_error }
          end

          context 'with all properties required disabled' do
            let(:openapi_all_properties_required) { false }

            it { expect { call }.not_to raise_error }
          end

          context 'with all properties required disabled in config but enabled in metadata' do
            let(:openapi_all_properties_required) { false }
            let(:metadata) { super().merge(openapi_all_properties_required: true) }

            it { expect { call }.not_to raise_error }
          end

          context 'with all properties required enabled in config but disabled in metadata' do
            let(:openapi_all_properties_required) { true }
            let(:metadata) { super().merge(openapi_all_properties_required: false) }

            it { expect { call }.not_to raise_error }
          end

          context 'with no additional properties enabled' do
            let(:openapi_no_additional_properties) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties disabled' do
            let(:openapi_no_additional_properties) { false }

            it { expect { call }.not_to raise_error }
          end

          context 'with no additional properties validation disabled in config but enabled in metadata' do
            let(:openapi_no_additional_properties) { false }
            let(:metadata) { super().merge(openapi_no_additional_properties: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties validation enabled in config but disabled in metadata' do
            let(:openapi_no_additional_properties) { true }
            let(:metadata) { super().merge(openapi_no_additional_properties: false) }

            it { expect { call }.not_to raise_error }
          end

          context 'when schema does not have required property' do
            let(:schema) do
              {
                type: :object,
                properties: {
                  text: { type: :string },
                  number: { type: :integer }
                }
              }
            end

            context 'with all properties required enabled' do
              let(:openapi_all_properties_required) { true }

              it { expect { call }.not_to raise_error }
            end

            context 'with all properties required disabled' do
              let(:openapi_all_properties_required) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with all properties required disabled in config but enabled in metadata' do
              let(:openapi_all_properties_required) { false }
              let(:metadata) { super().merge(openapi_all_properties_required: true) }

              it { expect { call }.not_to raise_error }
            end

            context 'with all properties required enabled in config but disabled in metadata' do
              let(:openapi_all_properties_required) { true }
              let(:metadata) { super().merge(openapi_all_properties_required: false) }

              it { expect { call }.not_to raise_error }
            end

            context 'with no additional properties enabled' do
              let(:openapi_no_additional_properties) { true }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with no additional properties disabled' do
              let(:openapi_no_additional_properties) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with no additional properties validation disabled in config but enabled in metadata' do
              let(:openapi_no_additional_properties) { false }
              let(:metadata) { super().merge(openapi_no_additional_properties: true) }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with no additional properties validation enabled in config but disabled in metadata' do
              let(:openapi_no_additional_properties) { true }
              let(:metadata) { super().merge(openapi_no_additional_properties: false) }

              it { expect { call }.not_to raise_error }
            end
          end
        end

        context 'when response body has missing properties' do
          before { response.body = '{"number": 3}' }

          context 'with all properties required enabled' do
            let(:openapi_all_properties_required) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with all properties required disabled' do
            let(:openapi_all_properties_required) { false }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with all properties required disabled in config but enabled in metadata' do
            let(:openapi_all_properties_required) { false }
            let(:metadata) { super().merge(openapi_all_properties_required: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with all properties required enabled in config but disabled in metadata' do
            let(:openapi_all_properties_required) { true }
            let(:metadata) { super().merge(openapi_all_properties_required: false) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties enabled' do
            let(:openapi_no_additional_properties) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties disabled' do
            let(:openapi_no_additional_properties) { false }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties validation disabled in config but enabled in metadata' do
            let(:openapi_no_additional_properties) { false }
            let(:metadata) { super().merge(openapi_no_additional_properties: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties validation enabled in config but disabled in metadata' do
            let(:openapi_no_additional_properties) { true }
            let(:metadata) { super().merge(openapi_no_additional_properties: false) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end
        end

        context 'when response body has missing properties and additional properties' do
          before { response.body = '{"foo":"Some comment", "text":"bar"}' }

          context 'with all properties required enabled' do
            let(:openapi_all_properties_required) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with all properties required disabled' do
            let(:openapi_all_properties_required) { false }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with all properties required disabled in config but enabled in metadata' do
            let(:openapi_all_properties_required) { false }
            let(:metadata) { super().merge(openapi_all_properties_required: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with all properties required enabled in config but disabled in metadata' do
            let(:openapi_all_properties_required) { true }
            let(:metadata) { super().merge(openapi_all_properties_required: false) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties enabled' do
            let(:openapi_no_additional_properties) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties disabled' do
            let(:openapi_no_additional_properties) { false }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties validation disabled in config but enabled in metadata' do
            let(:openapi_no_additional_properties) { false }
            let(:metadata) { super().merge(openapi_no_additional_properties: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with no additional properties validation enabled in config but disabled in metadata' do
            let(:openapi_no_additional_properties) { true }
            let(:metadata) { super().merge(openapi_no_additional_properties: false) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'when schema does not have required property' do
            let(:schema) do
              {
                type: :object,
                properties: {
                  text: { type: :string },
                  number: { type: :integer }
                }
              }
            end

            context 'with all properties required enabled' do
              let(:openapi_all_properties_required) { true }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with all properties required disabled' do
              let(:openapi_all_properties_required) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with all properties required disabled in config but enabled in metadata' do
              let(:openapi_all_properties_required) { false }
              let(:metadata) { super().merge(openapi_all_properties_required: true) }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with all properties required enabled in config but disabled in metadata' do
              let(:openapi_all_properties_required) { true }
              let(:metadata) { super().merge(openapi_all_properties_required: false) }

              it { expect { call }.not_to raise_error }
            end

            context 'with no additional properties enabled' do
              let(:openapi_no_additional_properties) { true }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with no additional properties disabled' do
              let(:openapi_no_additional_properties) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with no additional properties validation disabled in config but enabled in metadata' do
              let(:openapi_no_additional_properties) { false }
              let(:metadata) { super().merge(openapi_no_additional_properties: true) }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with no additional properties validation enabled in config but disabled in metadata' do
              let(:openapi_no_additional_properties) { true }
              let(:metadata) { super().merge(openapi_no_additional_properties: false) }

              it { expect { call }.not_to raise_error }
            end
          end
        end

        context 'referenced schemas' do
          context 'components/schemas' do
            before do
              openapi_spec[:components] = {
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
                Response.new(
                  code: '200',
                  headers: {
                    'X-Rate-Limit-Limit' => '10',
                    'X-Cursor' => 'test_cursor',
                    'X-Per-Page' => 25
                  },
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
                  it { expect { call }.not_to raise_error }
                end
              end

              context 'using nullable attribute' do
                before do
                  metadata[:response][:schema][:properties][:blog]['nullable'] = true
                end

                context 'response matches metadata' do
                  it { expect { call }.not_to raise_error }
                end
              end
            end

            context 'nullable oneOf with referenced schema' do
              let(:response) do
                Response.new(
                  code: '200',
                  headers: {
                    'X-Rate-Limit-Limit' => '10',
                    'X-Cursor' => 'test_cursor',
                    'X-Per-Page' => 25
                  },
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
                  it { expect { call }.not_to raise_error }
                end
              end

              context 'using nullable attribute' do
                before do
                  metadata[:response][:schema][:properties][:blog]['nullable'] = true
                end

                context 'response matches metadata' do
                  it { expect { call }.not_to raise_error }
                end
              end
            end
          end
        end

        context 'oneOf with discriminator' do
          let(:response) do
            OpenStruct.new(
              code: '200',
              headers: {
                'X-Rate-Limit-Limit' => '10',
                'X-Cursor' => 'test_cursor',
                'X-Per-Page' => 25
              },
              body: '{ "blog": { "bar": "baz", "blog_type": "other_blog" } }'
            )
          end

          before do
            openapi_spec[:components] = {
              schemas: {
                'blog' => {
                  type: :object,
                  properties: {
                    foo: { type: :string },
                    blog_type: { type: :string }
                  },
                  required: ['foo']
                },
                'other_blog' => {
                  type: :object,
                  properties: {
                    bar: { type: :string },
                    blog_type: { type: :string }
                  },
                  required: %w[bar blog_type]
                }
              }
            }

            metadata[:response][:schema] = {
              properties: {
                blog: {
                  oneOf: [
                    { '$ref' => '#/components/schemas/blog' },
                    { '$ref' => '#/components/schemas/other_blog' },
                  ],
                  discriminator: {
                    propertyName: 'blog_type'
                  }
                }
              },
              required: ['blog']
            }
          end

          context 'response with implicit mapping' do
            it { expect { call }.to_not raise_error }
          end

          context 'response with explicit mapping' do
            before do
              metadata[:response][:schema][:properties][:blog][:discriminator][:mapping] = {
                'blog' => '#/components/schemas/blog',
                'other_blog' => '#/components/schemas/other_blog'
              }
            end

            it { expect { call }.to_not raise_error }
          end
        end
      end
    end
  end
end
