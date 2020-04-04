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
      let(:config) { double('config') }
      let(:output) { double('output').as_null_object }
      let(:swagger_root) { File.expand_path('tmp/swagger', __dir__) }

      describe '#example_group_finished(notification)' do
        before do
          allow(config).to receive(:get_swagger_doc).and_return(swagger_doc)
          subject.example_group_finished(notification)
        end
        let(:notification) { OpenStruct.new(group: OpenStruct.new(metadata: api_metadata)) }
        let(:api_metadata) do
          {
            path_item: { template: '/blogs', parameters: [{ type: :string }] },
            operation: { verb: :post, summary: 'Creates a blog', parameters: [{ type: :string }] },
            response: { code: '201', description: 'blog created', headers: { type: :string }, schema: { '$ref' => '#/definitions/blog' } },
            document: document
          }
        end

        context 'with the document tag set to false' do
          let(:swagger_doc) { { swagger: '2.0' } }
          let(:document) { false }

          it 'does not update the swagger doc' do
            expect(swagger_doc).to match({ swagger: '2.0' })
          end
        end

        context 'with the document tag set to anything but false' do
          let(:swagger_doc) { { swagger: '2.0' } }
          # anything works, including its absence when specifying responses.
          let(:document) { nil }

          it 'converts to swagger and merges into the corresponding swagger doc' do
            expect(swagger_doc).to match(
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
          let(:swagger_doc) do
            {
              openapi: '3.0.1',
              basePath: '/foo',
              schemes: ['http', 'https'],
              host: 'api.example.com',
              produces: ['application/vnd.my_mime', 'application/json'],
              components: {
                securitySchemes: {
                  my_oauth: {
                    type: :oauth2,
                    flow: :anything,
                    token_url: :somewhere
                  }
                }
              }
            }
          end
          let(:document) { nil }

          it 'converts query and path params, type: to schema: { type: }' do
            expect(swagger_doc.slice(:paths)).to match(
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
            )
          end

          it 'converts basePath, schemas and host to urls' do
            expect(swagger_doc.slice(:servers)).to match(
              servers: {
                urls: ['http://api.example.com/foo', 'https://api.example.com/foo']
              }
            )
          end

          it 'upgrades oauth flow to flows' do
            expect(swagger_doc.slice(:components)).to match(
              components: {
                securitySchemes: {
                  my_oauth: {
                    type: :oauth2,
                    flows: {
                      anything: {
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
        before do
          FileUtils.rm_r(swagger_root) if File.exist?(swagger_root)
          allow(config).to receive(:swagger_docs).and_return(
            'v1/swagger.json' => { info: { version: 'v1' } },
            'v2/swagger.json' => { info: { version: 'v2' } }
          )
          allow(config).to receive(:swagger_format).and_return(swagger_format)
          subject.stop(notification)
        end

        let(:notification) { double('notification') }
        context 'with default format' do
          let(:swagger_format) { :json }

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

        after do
          FileUtils.rm_r(swagger_root) if File.exist?(swagger_root)
        end
      end
    end
  end
end
