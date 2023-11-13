# frozen_string_literal: true

require 'rswag/specs/openapi_formatter'
require 'ostruct'

module Rswag
  module Specs
    RSpec.describe OpenapiFormatter do
      subject { described_class.new(output, config) }

      # Mock out some infrastructure
      before do
        allow(config).to receive(:openapi_root).and_return(openapi_root)

        allow(ActiveSupport::Deprecation).to receive(:warn) # Silence deprecation output from specs
      end
      let(:config) { double('config') }
      let(:output) { double('output').as_null_object }
      let(:openapi_root) { File.expand_path('tmp/openapi', __dir__) }

      describe '#example_group_finished(notification)' do
        before do
          allow(config).to receive(:get_openapi_spec).and_return(openapi_spec)
          subject.example_group_finished(notification)
        end
        let(:request_examples) { nil }
        let(:notification) { OpenStruct.new(group: OpenStruct.new(metadata: api_metadata)) }
        let(:api_metadata) do
          operation = { verb: :post, summary: 'Creates a blog', parameters: [{ type: :string }] }
          if request_examples
            operation[:request_examples] = request_examples
          end
          {
            path_item: { template: '/blogs', parameters: [{ type: :string }] },
            operation: operation,
            response: response_metadata,
            document: document
          }
        end
        let(:response_metadata) { { code: '201', description: 'blog created', headers: { type: :string }, schema: { '$ref' => '#/components/schemas/blog' } } }

        context 'with the document tag set to false' do
          let(:openapi_spec) { { openapi: '3.0' } }
          let(:document) { false }

          it 'does not update the openapi doc' do
            expect(openapi_spec).to match({ openapi: '3.0' })
          end
        end

        context 'with the document tag set to anything but false' do
          let(:openapi_spec) { { openapi: '3.0' } }
          # anything works, including its absence when specifying responses.
          let(:document) { nil }

          it 'converts to openapi and merges into the corresponding openapi doc' do
            expect(openapi_spec).to match(
            {
            openapi: "3.0",
            paths: {
              '/blogs' => {
                parameters: [{:schema=>{:type=>:string}}],
                post: {
                  parameters: [{:schema=>{:type=>:string}}],
                  summary: "Creates a blog",
                  responses: {
                    '201' => {
                      description: "blog created",
                      headers: {:schema=>{:type=>:string}}}}}}}}
            )
          end
        end
      end

      describe '#stop' do
        before do
          FileUtils.rm_r(openapi_root) if File.exist?(openapi_root)
          allow(config).to receive(:openapi_specs).and_return(
            'v1/openapi.json' => doc_1,
            'v2/openapi.json' => doc_2
          )
          allow(config).to receive(:openapi_format).and_return(openapi_format)
          subject.stop(notification)
        end

        let(:doc_1) { { info: { version: 'v1' } } }
        let(:doc_2) { { info: { version: 'v2' } } }
        let(:openapi_format) { :json }

        let(:notification) { double('notification') }
        context 'with default format' do
          it 'writes the openapi_spec(s) to file' do
            expect(File).to exist("#{openapi_root}/v1/openapi.json")
            expect(File).to exist("#{openapi_root}/v2/openapi.json")
            expect { JSON.parse(File.read("#{openapi_root}/v2/openapi.json")) }.not_to raise_error
          end
        end

        context 'with yaml format' do
          let(:openapi_format) { :yaml }

          it 'writes the openapi_spec(s) as yaml' do
            expect(File).to exist("#{openapi_root}/v1/openapi.json")
            expect { JSON.parse(File.read("#{openapi_root}/v1/openapi.json")) }.to raise_error(JSON::ParserError)
            # Psych::DisallowedClass would be raised if we do not pre-process ruby symbols
            expect { YAML.safe_load(File.read("#{openapi_root}/v1/openapi.json")) }.not_to raise_error
          end
        end

        context 'with oauth3 upgrades' do
          let(:doc_2) do
            {
              paths: {
                '/path/' => {
                  get: {
                    summary: 'Retrieve Nested Paths',
                    tags: ['nested Paths'],
                    produces: ['application/json'],
                    consumes: ['application/xml', 'application/json'],
                    parameters: [{
                      in: :body,
                      schema: { foo: :bar }
                    }, {
                      in: :headers
                    }]
                  }
                }
              }
            }
          end

          it 'removes remaining consumes/produces' do
            expect(doc_2[:paths]['/path/'][:get].keys).to eql([:summary, :tags, :parameters, :requestBody])
          end

          it 'duplicates params in: :body to requestBody from consumes list' do
            expect(doc_2[:paths]['/path/'][:get][:parameters]).to eql([{ in: :headers }])
            expect(doc_2[:paths]['/path/'][:get][:requestBody]).to eql(content: {
              'application/xml' => { schema: { foo: :bar } },
              'application/json' => { schema: { foo: :bar } }
            })
          end
        end

        context 'with oauth3 formData' do
          let(:doc_2) do
            {
              paths: {
                '/path/' => {
                  post: {
                    summary: 'Retrieve Nested Paths',
                    tags: ['nested Paths'],
                    produces: ['application/json'],
                    consumes: ['multipart/form-data'],
                    parameters: [{
                      in: :formData,
                      schema: { type: :file }
                    },{
                      in: :headers
                    }]
                  }
                }
              }
            }
          end

          it 'removes remaining consumes/produces' do
            expect(doc_2[:paths]['/path/'][:post].keys).to eql([:summary, :tags, :parameters, :requestBody])
          end

          it 'duplicates params in: :formData to requestBody from consumes list' do
            expect(doc_2[:paths]['/path/'][:post][:parameters]).to eql([{ in: :headers }])
            expect(doc_2[:paths]['/path/'][:post][:requestBody]).to eql(content: {
              'multipart/form-data' => { schema: { type: :file } }
            })
          end
        end

        context 'with descriptions on the body param' do
          let(:doc_2) do
            {
              paths: {
                '/path/' => {
                  post: {
                    produces: ['application/json'],
                    consumes: ['application/json'],
                    parameters: [{
                      in: :body,
                      description: "description",
                      schema: { type: :number }
                    }]
                  }
                }
              }
            }
          end

          it 'puts the description in the doc' do
            expect(doc_2[:paths]['/path/'][:post][:requestBody][:description]).to eql('description')
          end
        end

        after do
          FileUtils.rm_r(openapi_root) if File.exist?(openapi_root)
        end


        context 'with request examples' do
          let(:doc_2) do
            {
              paths: {
                '/path/' => {
                  post: {
                    summary: 'Retrieve Nested Paths',
                    tags: ['nested Paths'],
                    produces: ['application/json'],
                    consumes: ['application/json'],
                    parameters: [{
                      in: :body,
                      schema: {
                        '$ref': '#/components/schemas/BlogPost'
                      }
                    },{
                      in: :headers
                    }],
                    request_examples: [
                      {
                        name: 'basic',
                        value: {
                          some_field: 'Foo'
                        },
                        summary: 'An example'
                      },
                      {
                        name: 'another_basic',
                        value: {
                          some_field: 'Bar'
                        }
                      }
                    ],
                  }
                }
              },
              components: {
                schemas: {
                  'BlogPost' => {
                    type: 'object',
                    properties: {
                      some_field: {
                        type: 'string',
                        description: 'description'
                      }
                    }
                  }
                }
              }
            }
          end

          it 'removes remaining request_examples' do
            expect(doc_2[:paths]['/path/'][:post].keys).to eql([:summary, :tags, :parameters, :requestBody])
          end

          it 'creates requestBody examples' do
            expect(doc_2[:paths]['/path/'][:post][:parameters]).to eql([{ in: :headers }])
            expect(doc_2[:paths]['/path/'][:post][:requestBody]).to eql(content: {
              'application/json' => {
                schema: { '$ref': '#/components/schemas/BlogPost' },
                examples: {
                  'basic' => {
                    value: {
                      some_field: 'Foo'
                    },
                    summary: 'An example'
                  },
                  'another_basic' => {
                    value: {
                      some_field: 'Bar'
                    },
                    summary: 'Retrieve Nested Paths'
                  }
                }
              }
            })
          end
        end

        after do
          FileUtils.rm_r(openapi_root) if File.exist?(openapi_root)
        end
      end
    end
  end
end
