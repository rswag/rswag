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

        allow(ActiveSupport::Deprecation).to receive(:warn) # Silence deprecation output from specs
      end
      let(:config) { double('config') }
      let(:output) { double('output').as_null_object }
      let(:swagger_root) { File.expand_path('tmp/swagger', __dir__) }

      describe '#example_group_finished(notification)' do
        before do
          allow(config).to receive(:get_swagger_doc).and_return(swagger_doc)
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
        let(:response_metadata) { { code: '201', description: 'blog created', headers: { type: :string }, schema: { '$ref' => '#/definitions/blog' } } }

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

          context 'with response example' do
            let(:response_metadata) do
              {
                code: '201',
                description: 'blog created',
                headers: { type: :string },
                content: { 'application/json' => { example: { foo: :bar } } },
                schema: { '$ref' => '#/definitions/blog' }
              }
            end

            it 'adds example to definition' do
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
                              schema: { '$ref' => '#/definitions/blog' },
                              example: { foo: :bar }
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
          end

          context 'with empty content' do
            let(:swagger_doc) do
              {
                openapi: '3.0.1',
                basePath: '/foo',
                schemes: ['http', 'https'],
                host: 'api.example.com',
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
            end

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
                          description: 'blog created',
                          headers: { schema: { type: :string } }
                        }
                      }
                    }
                  }
                }
              )
            end
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
        before do
          FileUtils.rm_r(swagger_root) if File.exist?(swagger_root)
          allow(config).to receive(:swagger_docs).and_return(
            'v1/swagger.json' => doc_1,
            'v2/swagger.json' => doc_2
          )
          allow(config).to receive(:swagger_format).and_return(swagger_format)
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
          FileUtils.rm_r(swagger_root) if File.exist?(swagger_root)
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
          FileUtils.rm_r(swagger_root) if File.exist?(swagger_root)
        end
      end
    end
  end
end
