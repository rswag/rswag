# frozen_string_literal: true

require 'rswag/specs/swagger_formatter'
require 'ostruct'

module Rswag
  module Specs
    RSpec.describe SwaggerFormatter do
      subject { described_class.new(output, config) }

      # Mock out some infrastructure
      before do
        allow(config).to receive(:swagger_root).and_return(swagger_root)
      end
      let(:config) {
        Configuration.new(
          OpenStruct.new(
            swagger_root: swagger_root,
            swagger_docs: config_swagger_docs,
            swagger_format: swagger_format
          )
        )
      }
      let(:swagger_format) { :json }
      let(:output) { double('output').as_null_object }
      let(:swagger_root) { File.expand_path('tmp/swagger', __dir__) }

      describe '#example_group_finished(notification)' do
        before do
          subject.example_group_finished(notification)
        end
        let(:notification) { OpenStruct.new(group: OpenStruct.new(metadata: api_metadata)) }
        let(:config_swagger_docs) { {} }
        let(:api_metadata) do
          {
            path_item: { template: '/blogs', parameters: [{ type: :string }] },
            operation: { verb: :post, summary: 'Creates a blog', parameters: [{ type: :string }] },
            response: { code: '201', description: 'blog created', headers: { type: :string }, schema: { '$ref' => '#/definitions/blog' } },
            document: document,
            swagger_docs: swagger_docs
          }
        end

        context 'with the document tag set to false' do
          let(:config_swagger_docs) { { 'doc_1' => { swagger: '2.0' } } }
          let(:swagger_doc) { 'doc_1' }
          let(:document) { false }
          let(:swagger_docs) { nil }

          it 'does not update the swagger doc' do
            expect(config_swagger_docs[swagger_doc]).to match({ swagger: '2.0' })
          end
        end

        context 'with the document tag set to anything but false' do
          let(:config_swagger_docs) { { 'doc_1' => { swagger: '2.0' } } }
          let(:swagger_doc) { 'doc_1' }
          # anything works, including its absence when specifying responses.
          let(:document) { nil }
          let(:swagger_docs) { nil }

          it 'converts to swagger and merges into the corresponding swagger doc' do
            expect(config_swagger_docs[swagger_doc]).to match(
              swagger: '2.0',
              paths: {
                '/blogs' => {
                  parameters: [{ type: :string }],
                  post: {
                    parameters: [{ type: :string }],
                    summary: 'Creates a blog',
                    responses: {
                      '201' => {
                        description: 'blog created',
                        headers: { type: :string },
                        schema: { '$ref' => '#/definitions/blog' }
                      }
                    }
                  }
                }
              }
            )
          end
        end

        context 'with metadata upgrades for 3.0' do
          let(:openapi_documents) {
            (0..2).map { |idx|
              {
                openapi: '3.0.1',
                basePath: '/foo',
                title: "Doc #{idx}",
                schemes: ['http', 'https'],
                host: 'api.example.com',
                produces: ['application/vnd.my_mime', 'application/json'],
                components: {
                  securitySchemes: {
                    myClientCredentials: {
                      type: :oauth2,
                      flow: :application,
                      token_url: :somewhere
                    },
                    myAuthorizationCode: {
                      type: :oauth2,
                      flow: :accessCode,
                      token_url: :somewhere
                    },
                    myImplicit: {
                      type: :oauth2,
                      flow: :implicit,
                      token_url: :somewhere
                    }
                  }
                }
              }
            }
          }
          let(:config_swagger_docs) { { 'doc_1' => openapi_documents[0] } }
          let(:swagger_doc) { 'doc_1' }
          let(:document) { nil }
          let(:swagger_docs) { nil }
          let(:expected_paths) {
            {
              paths: {
                '/blogs' => {
                  parameters: [{ schema: { type: :string } }],
                  post: {
                    parameters: [{ schema: { type: :string } }],
                    summary: 'Creates a blog',
                    responses: {
                      '201' => {
                        content: {
                          'application/vnd.my_mime' => {
                            schema: { '$ref' => '#/definitions/blog' }
                          },
                          'application/json' => {
                            schema: { '$ref' => '#/definitions/blog' }
                          }
                        },
                        description: 'blog created',
                        headers: { schema: { type: :string } }
                      }
                    }
                  }
                }
              }
            }
          }

          it 'converts query and path params, type: to schema: { type: }' do
            expect(config_swagger_docs[swagger_doc].slice(:paths)).to match(expected_paths)
          end

          context 'when swagger_docs contains one of the docs' do
            let(:config_swagger_docs) {
              {
                'doc_1' => openapi_documents[0],
                'doc_2' => openapi_documents[1]
              }
            }
            let(:swagger_doc) { nil }
            let(:swagger_docs) { ['doc_1'] }

            it 'ads the paths to the document' do
              expect(config_swagger_docs['doc_1'].slice(:paths)).to match(expected_paths)
              expect(config_swagger_docs['doc_2'].slice(:paths)).not_to match(expected_paths)
            end
          end

          context 'when swagger_docs contains multiple docs' do
            let(:config_swagger_docs) {
              {
                'doc_1' => openapi_documents[0],
                'doc_2' => openapi_documents[1]
              }
            }
            let(:swagger_doc) { nil }
            let(:swagger_docs) { ['doc_1', 'doc_2'] }

            it 'ads the paths to the document' do
              expect(config_swagger_docs['doc_1'].slice(:paths)).to match(expected_paths)
              expect(config_swagger_docs['doc_2'].slice(:paths)).to match(expected_paths)
            end
          end

          it 'converts basePath, schemas and host to urls' do
            expect(config_swagger_docs[swagger_doc].slice(:servers)).to match(
              servers: {
                urls: ['http://api.example.com/foo', 'https://api.example.com/foo']
              }
            )
          end

          it 'upgrades oauth flow to flows' do
            expect(config_swagger_docs[swagger_doc].slice(:components)).to match(
              components: {
                securitySchemes: {
                  myClientCredentials: {
                    type: :oauth2,
                    flows: {
                      'clientCredentials' => {
                        token_url: :somewhere
                      }
                    }
                  },
                  myAuthorizationCode: {
                    type: :oauth2,
                    flows: {
                      'authorizationCode' => {
                        token_url: :somewhere
                      }
                    }
                  },
                  myImplicit: {
                    type: :oauth2,
                    flows: {
                      'implicit' => {
                        token_url: :somewhere
                      }
                    }
                  }
                }
              }
            )
          end
        end
      end

      describe '#stop' do
        let(:config_swagger_docs) {
          {
            'v1/swagger.json' => doc_1,
            'v2/swagger.json' => doc_2
          }
        }
        before do
          FileUtils.rm_r(swagger_root) if File.exist?(swagger_root)
          subject.stop(notification)
        end

        let(:doc_1) { { info: { version: 'v1' } } }
        let(:doc_2) { { info: { version: 'v2' } } }
        let(:swagger_format) { :json }

        let(:notification) { double('notification') }
        context 'with default format' do
          it 'writes the swagger_doc(s) to file' do
            expect(File).to exist("#{swagger_root}/v1/swagger.json")
            expect(File).to exist("#{swagger_root}/v2/swagger.json")
            expect { JSON.parse(File.read("#{swagger_root}/v2/swagger.json")) }.not_to raise_error
          end
        end

        context 'with yaml format' do
          let(:swagger_format) { :yaml }

          it 'writes the swagger_doc(s) as yaml' do
            expect(File).to exist("#{swagger_root}/v1/swagger.json")
            expect { JSON.parse(File.read("#{swagger_root}/v1/swagger.json")) }.to raise_error(JSON::ParserError)
            # Psych::DisallowedClass would be raised if we do not pre-process ruby symbols
            expect { YAML.safe_load(File.read("#{swagger_root}/v1/swagger.json")) }.not_to raise_error
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

        after do
          FileUtils.rm_r(swagger_root) if File.exist?(swagger_root)
        end
      end
    end
  end
end
