# frozen_string_literal: true

require 'rswag/specs/response_validator'

module Rswag
  module Specs
    RSpec.describe ResponseValidator do
      subject { described_class.new(config) }

      before do
        allow(config).to receive_messages(
          get_openapi_spec: openapi_spec,
          openapi_all_properties_required: openapi_all_properties_required,
          openapi_no_additional_properties: openapi_no_additional_properties
        )
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

      describe '#validate!(metadata, response)' do
        let(:call) { subject.validate!(metadata, response) }
        let(:response) do
          OpenStruct.new(
            code: '200',
            headers: {
              'X-Rate-Limit-Limit' => '10',
              'X-Cursor' => 'test_cursor',
              'X-Per-Page' => 25
            },
            body: '{"text":"Some comment", "number": 3}'
          )
        end

        context 'when the response matches metadata' do
          it { expect { call }.not_to raise_error }
        end

        context 'when the response code differs from metadata' do
          before { response.code = '400' }

          it { expect { call }.to raise_error(/Expected response code/) }
        end

        context 'when the response headers differ from metadata' do
          before { response.headers = {} }

          it { expect { call }.to raise_error(/Expected response header/) }
        end

        context 'when the response headers do not include optional header' do
          before do
            response.headers = {
              'X-Rate-Limit-Limit' => '10',
              'X-Per-Page' => 25
            }
          end

          it { expect { call }.not_to raise_error }
        end

        context 'when the response headers include nullable header' do
          before do
            response.headers = {
              'X-Rate-Limit-Limit' => '10',
              'X-Cursor' => 'test_cursor',
              'X-Per-Page' => nil
            }
          end

          it { expect { call }.not_to raise_error }
        end

        context 'when the response headers missing nullable header' do
          before do
            response.headers = {
              'X-Rate-Limit-Limit' => '10',
              'X-Cursor' => 'test_cursor'
            }
          end

          it { expect { call }.to raise_error(/Expected response header/) }
        end

        context 'when the response body differs from metadata' do
          before { response.body = '{"foo":"Some comment"}' }

          it { expect { call }.to raise_error(/Expected response body/) }
        end

        context 'when the response body does not have additional properties or missing properties' do
          # TODO: DRY up these specs
          # eg.
          # context 'with global `openapi_all_properties_required: false`' do
          #   let(:openapi_all_properties_required) { true }

          #   it { expect { correct_properties_response }.not_to raise_error }
          #   it { expect { missing_properties_response }.to raise_error }
          #   it { expect { extra_properties_response }.not_to raise_error }
          #   it { expect { missing_and_extra_properties_response }.to raise_error }
          # end

          context 'with global `openapi_all_properties_required: true`' do
            let(:openapi_all_properties_required) { true }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_all_properties_required: false`' do
            let(:openapi_all_properties_required) { false }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_all_properties_required: false` in config but enabled in metadata' do
            let(:openapi_all_properties_required) { false }
            let(:metadata) { super().merge(openapi_all_properties_required: true) }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_all_properties_required: true` in config but disabled in metadata' do
            let(:openapi_all_properties_required) { true }
            let(:metadata) { super().merge(openapi_all_properties_required: false) }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_no_additional_properties: true`' do
            let(:openapi_no_additional_properties) { true }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_no_additional_properties: false`' do
            let(:openapi_no_additional_properties) { false }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_no_additional_properties: false` in config but enabled in metadata' do
            let(:openapi_no_additional_properties) { false }
            let(:metadata) { super().merge(openapi_no_additional_properties: true) }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_no_additional_properties: true` in config but disabled in metadata' do
            let(:openapi_no_additional_properties) { true }
            let(:metadata) { super().merge(openapi_no_additional_properties: false) }

            it { expect { call }.not_to raise_error }
          end

          context 'when the schema properties are not explicitly listed as required' do
            let(:schema) do
              {
                type: :object,
                properties: {
                  text: { type: :string },
                  number: { type: :integer }
                }
              }
            end

            context 'with global `openapi_all_properties_required: true`' do
              let(:openapi_all_properties_required) { true }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_all_properties_required: false`' do
              let(:openapi_all_properties_required) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_all_properties_required: false` in config but enabled in metadata' do
              let(:openapi_all_properties_required) { false }
              let(:metadata) { super().merge(openapi_all_properties_required: true) }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_all_properties_required: true` in config but disabled in metadata' do
              let(:openapi_all_properties_required) { true }
              let(:metadata) { super().merge(openapi_all_properties_required: false) }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_no_additional_properties: true`' do
              let(:openapi_no_additional_properties) { true }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_no_additional_properties: false`' do
              let(:openapi_no_additional_properties) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_no_additional_properties: false` in config but enabled in metadata' do
              let(:openapi_no_additional_properties) { false }
              let(:metadata) { super().merge(openapi_no_additional_properties: true) }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_no_additional_properties: true` in config but disabled in metadata' do
              let(:openapi_no_additional_properties) { true }
              let(:metadata) { super().merge(openapi_no_additional_properties: false) }

              it { expect { call }.not_to raise_error }
            end
          end
        end

        context 'when the response body has additional properties' do
          before { response.body = '{"foo":"Some comment", "number": 3, "text":"bar"}' }

          context 'with global `openapi_all_properties_required: true`' do
            let(:openapi_all_properties_required) { true }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_all_properties_required: false`' do
            let(:openapi_all_properties_required) { false }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_all_properties_required: false` in config but enabled in metadata' do
            let(:openapi_all_properties_required) { false }
            let(:metadata) { super().merge(openapi_all_properties_required: true) }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_all_properties_required: true` in config but disabled in metadata' do
            let(:openapi_all_properties_required) { true }
            let(:metadata) { super().merge(openapi_all_properties_required: false) }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_no_additional_properties: true`' do
            let(:openapi_no_additional_properties) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: false`' do
            let(:openapi_no_additional_properties) { false }

            it { expect { call }.not_to raise_error }
          end

          context 'with global `openapi_no_additional_properties: false` in config but enabled in metadata' do
            let(:openapi_no_additional_properties) { false }
            let(:metadata) { super().merge(openapi_no_additional_properties: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: true` in config but disabled in metadata' do
            let(:openapi_no_additional_properties) { true }
            let(:metadata) { super().merge(openapi_no_additional_properties: false) }

            it { expect { call }.not_to raise_error }
          end

          context 'when the schema properties are not explicitly listed as required' do
            let(:schema) do
              {
                type: :object,
                properties: {
                  text: { type: :string },
                  number: { type: :integer }
                }
              }
            end

            context 'with global `openapi_all_properties_required: true`' do
              let(:openapi_all_properties_required) { true }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_all_properties_required: false`' do
              let(:openapi_all_properties_required) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_all_properties_required: false` in config but enabled in metadata' do
              let(:openapi_all_properties_required) { false }
              let(:metadata) { super().merge(openapi_all_properties_required: true) }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_all_properties_required: true` in config but disabled in metadata' do
              let(:openapi_all_properties_required) { true }
              let(:metadata) { super().merge(openapi_all_properties_required: false) }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_no_additional_properties: true`' do
              let(:openapi_no_additional_properties) { true }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with global `openapi_no_additional_properties: false`' do
              let(:openapi_no_additional_properties) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_no_additional_properties: false` in config but enabled in metadata' do
              let(:openapi_no_additional_properties) { false }
              let(:metadata) { super().merge(openapi_no_additional_properties: true) }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with global `openapi_no_additional_properties: true` in config but disabled in metadata' do
              let(:openapi_no_additional_properties) { true }
              let(:metadata) { super().merge(openapi_no_additional_properties: false) }

              it { expect { call }.not_to raise_error }
            end
          end
        end

        context 'when response body has missing properties' do
          before { response.body = '{"number": 3}' }

          context 'with global `openapi_all_properties_required: true`' do
            let(:openapi_all_properties_required) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_all_properties_required: false`' do
            let(:openapi_all_properties_required) { false }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_all_properties_required: false` in config but enabled in metadata' do
            let(:openapi_all_properties_required) { false }
            let(:metadata) { super().merge(openapi_all_properties_required: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_all_properties_required: true` in config but disabled in metadata' do
            let(:openapi_all_properties_required) { true }
            let(:metadata) { super().merge(openapi_all_properties_required: false) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: true`' do
            let(:openapi_no_additional_properties) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: false`' do
            let(:openapi_no_additional_properties) { false }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: false` in config but enabled in metadata' do
            let(:openapi_no_additional_properties) { false }
            let(:metadata) { super().merge(openapi_no_additional_properties: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: true` in config but disabled in metadata' do
            let(:openapi_no_additional_properties) { true }
            let(:metadata) { super().merge(openapi_no_additional_properties: false) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end
        end

        context 'when the response body has missing properties and additional properties' do
          before { response.body = '{"foo":"Some comment", "text":"bar"}' }

          context 'with global `openapi_all_properties_required: true`' do
            let(:openapi_all_properties_required) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_all_properties_required: false`' do
            let(:openapi_all_properties_required) { false }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_all_properties_required: false` in config but enabled in metadata' do
            let(:openapi_all_properties_required) { false }
            let(:metadata) { super().merge(openapi_all_properties_required: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_all_properties_required: true` in config but disabled in metadata' do
            let(:openapi_all_properties_required) { true }
            let(:metadata) { super().merge(openapi_all_properties_required: false) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: true`' do
            let(:openapi_no_additional_properties) { true }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: false`' do
            let(:openapi_no_additional_properties) { false }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: false` in config but enabled in metadata' do
            let(:openapi_no_additional_properties) { false }
            let(:metadata) { super().merge(openapi_no_additional_properties: true) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'with global `openapi_no_additional_properties: true` in config but disabled in metadata' do
            let(:openapi_no_additional_properties) { true }
            let(:metadata) { super().merge(openapi_no_additional_properties: false) }

            it { expect { call }.to raise_error(/Expected response body/) }
          end

          context 'when the schema properties are not explicitly listed as required' do
            let(:schema) do
              {
                type: :object,
                properties: {
                  text: { type: :string },
                  number: { type: :integer }
                }
              }
            end

            context 'with global `openapi_all_properties_required: true`' do
              let(:openapi_all_properties_required) { true }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with global `openapi_all_properties_required: false`' do
              let(:openapi_all_properties_required) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_all_properties_required: false` in config but enabled in metadata' do
              let(:openapi_all_properties_required) { false }
              let(:metadata) { super().merge(openapi_all_properties_required: true) }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with global `openapi_all_properties_required: true` in config but disabled in metadata' do
              let(:openapi_all_properties_required) { true }
              let(:metadata) { super().merge(openapi_all_properties_required: false) }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_no_additional_properties: true`' do
              let(:openapi_no_additional_properties) { true }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with global `openapi_no_additional_properties: false`' do
              let(:openapi_no_additional_properties) { false }

              it { expect { call }.not_to raise_error }
            end

            context 'with global `openapi_no_additional_properties: false` in config but enabled in metadata' do
              let(:openapi_no_additional_properties) { false }
              let(:metadata) { super().merge(openapi_no_additional_properties: true) }

              it { expect { call }.to raise_error(/Expected response body/) }
            end

            context 'with global `openapi_no_additional_properties: true` in config but disabled in metadata' do
              let(:openapi_no_additional_properties) { true }
              let(:metadata) { super().merge(openapi_no_additional_properties: false) }

              it { expect { call }.not_to raise_error }
            end
          end
        end

        context 'when using schemas referenced from `components/schemas`' do
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

          context 'when the referenced schema has nullable annotations' do
            let(:response) do
              OpenStruct.new(
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

            context 'with OAS2 style `x-nullable` attribute' do
              before do
                metadata[:response][:schema][:properties][:blog]['x-nullable'] = true
              end

              it { expect { call }.not_to raise_error }
            end

            context 'with OAS3.0 style `nullable` attribute' do
              before do
                metadata[:response][:schema][:properties][:blog]['nullable'] = true
              end

              it { expect { call }.not_to raise_error }
            end
          end

          context 'when the referenced schema has a nullable oneOf' do
            let(:response) do
              OpenStruct.new(
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

            context 'with OAS2 style `x-nullable` attribute' do
              before do
                metadata[:response][:schema][:properties][:blog]['x-nullable'] = true
              end

              it { expect { call }.not_to raise_error }
            end

            context 'with OAS3.0 style `nullable` attribute' do
              before do
                metadata[:response][:schema][:properties][:blog]['nullable'] = true
              end

              it { expect { call }.not_to raise_error }
            end
          end
        end
      end
    end
  end
end
