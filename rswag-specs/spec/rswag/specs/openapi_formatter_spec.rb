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
        let(:response_metadata) { { code: '201', description: 'blog created', headers: {"Accept" => { type: :string }}, schema: { '$ref' => '#/components/schemas/blog' } } }

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
                parameters: [{:schema => {:type => :string}}],
                post: {
                  parameters: [{:schema => {:type => :string}}],
                  summary: "Creates a blog",
                  responses: {
                    '201' => {
                      description: "blog created",
                      headers: {"Accept" => {:schema => {:type => :string}}}}}}}}}
            )
          end
        end
      end

      describe '#stop' do
        before do
          FileUtils.rm_r(openapi_root) if File.exist?(openapi_root)
          allow(config).to receive(:openapi_specs).and_return(
            'v1/openapi.json' => doc_for_api_v1,
            'v2/openapi.json' => doc_for_api_v2
          )
          allow(config).to receive(:openapi_format).and_return(openapi_format)
          subject.stop(notification)
        end

        let(:doc_for_api_v1) { { info: { version: 'v1' } } }
        let(:doc_for_api_v2) { { info: { version: 'v2' } } }
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

        context 'with OAS3' do
          let(:doc_for_api_v2) do
            {
              paths: {
                '/path/' => {
                  get: {
                    summary: 'Retrieve Nested Paths',
                    tags: ['nested Paths'],
                    produces: ['application/json'],
                    consumes: ['application/xml', 'application/json'],
                    parameters: [{
                      in: :formData,
                      schema: { foo: :bar }
                    }, {
                      name: "Accept",
                      in: :headers,
                      type: :string
                    }],
                    security: [{ # Must provide both my_auth and oauth2_with_scopes
                      my_auth: [],
                      oauth2_with_scopes: [:scope1, :scope2]
                    }, { # or can auth with only auth_with_this
                      auth_with_this: []
                    }]
                  }
                }
              }
            }
          end

          it 'removes remaining consumes/produces' do
            expect(doc_for_api_v2[:paths]['/path/'][:get].keys).to include(:summary, :tags, :parameters, :requestBody, :security)
          end

          it 'params in: :formData appear in requestBody' do
            expect(doc_for_api_v2[:paths]['/path/'][:get][:parameters]).to eql([{ in: :headers, name: "Accept", schema: { type: :string } }])
            expect(doc_for_api_v2[:paths]['/path/'][:get][:requestBody]).to eql(content: {
              'application/xml' => { schema: { foo: :bar } },
              'application/json' => { schema: { foo: :bar } }
            })
          end

          it 'adds security to operation' do
            expect(doc_for_api_v2[:paths]['/path/'][:get][:security]).to eql([
              {
                my_auth: [],
                oauth2_with_scopes: [:scope1, :scope2]
              },
              {
                auth_with_this: []
              }
            ])
          end
        end

        context 'with formData' do
          let(:doc_for_api_v2) do
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
                      schema: { type: :string }
                    },{
                      name: "Accept",
                      in: :headers
                    }]
                  }
                },
                '/support_legacy_body/' => {
                  post: {
                    summary: 'Retrieve Nested Paths',
                    tags: ['nested Paths'],
                    produces: ['application/json'],
                    consumes: ['application/json'],
                    parameters: [{
                      in: :body,
                      schema: { type: :object, required: true }
                    }]
                  }
                },
                '/support_legacy_body_param_with_name/' => {
                  post: {
                    summary: 'Retrieve Nested Paths',
                    tags: ['nested Paths'],
                    produces: ['application/json'],
                    consumes: ['application/json'],
                    parameters: [{
                      name: :foo,
                      in: :body,
                      schema: {'$ref': '#/components/schemas/BlogPost'},
                      required: true
                    }]
                  }
                }
              }
            }
          end

          it 'removes remaining consumes/produces' do
            expect(doc_for_api_v2[:paths]['/path/'][:post].keys).to eql([:summary, :tags, :parameters, :requestBody])
          end

          it 'duplicates params in: :formData to requestBody from consumes list' do
            expect(doc_for_api_v2[:paths]['/path/'][:post][:parameters]).to eql([{ in: :headers, name: "Accept" }])
            expect(doc_for_api_v2[:paths]['/path/'][:post][:requestBody]).to eql(
              content: {
                'multipart/form-data' => { schema: { type: :string } }
              }
            )
          end

          it 'supports legacy body parameters' do
            expect(doc_for_api_v2[:paths]['/support_legacy_body/'][:post][:parameters]).to eql([])
            expect(doc_for_api_v2[:paths]['/support_legacy_body/'][:post][:requestBody]).to eql(
              content: {
                'application/json' => { schema: { type: :object} }
              },
              required: true
            )
          end

          it 'supports legacy body parameters with name' do
            expect(doc_for_api_v2[:paths]['/support_legacy_body_param_with_name/'][:post][:parameters]).to eql([])
            expect(doc_for_api_v2[:paths]['/support_legacy_body_param_with_name/'][:post][:requestBody]).to eql(
              content: { 'application/json' => { schema: { '$ref': '#/components/schemas/BlogPost' } } },
              required: true
            )
          end
        end

        context 'with enum parameters' do
          let(:doc_for_api_v2) do
            {
              paths: {
                '/path/' => {
                  get: {
                    summary: 'Retrieve Nested Paths',
                    tags: ['nested Paths'],
                    produces: ['application/json'],
                    consumes: ['application/json'],
                    parameters: [{
                      in: :query,
                      name: :foo,
                      enum: {
                        'bar': 'list bars',
                        'baz': 'lists people named baz'
                      },
                      description: 'get by foo'
                    }]
                  }
                }
              }
            }
          end

          it 'writes the enum description' do
            expect(doc_for_api_v2[:paths]['/path/'][:get][:parameters]).to match(
              [{
                in: :query,
                name: :foo,
                schema: {
                  enum: ["bar", "baz"]
                },
                description: "get by foo:\n * `bar` list bars\n * `baz` lists people named baz\n "
              }]
            )
          end
        end

        context 'with formData file upload' do
          let(:doc_for_api_v2) do
            {
              paths: {
                '/path/' => {
                  post: {
                    summary: 'Upload file',
                    produces: ['application/json'],
                    consumes: ['image/png', 'application/octet-stream'],
                    parameters: [
                      {
                        in: :formData,
                        schema: { type: :file }
                      }
                    ]
                  }
                }
              }
            }
          end

          it 'generates schema in requestBody for content type' do
            expect(doc_for_api_v2[:paths]['/path/'][:post][:requestBody]).to eql(content: {
              'image/png' => {schema: {type: :string, format: :binary}},
              'application/octet-stream' => {schema: {type: :string, format: :binary}}
            })
          end
        end

        context 'with formData file upload as part of multipart' do
          let(:doc_for_api_v2) do
            {
              paths: {
                '/path/' => {
                  post: {
                    summary: 'Upload file',
                    consumes: ['multipart/form-data'],
                    parameters: [
                      {
                        name: :myFile,
                        in: :formData,
                        schema: { type: :file },
                        encoding: {contentType: ['image/png', 'image/jpeg']}
                      },
                      {
                        name: :foo,
                        in: :formData,
                        schema: { type: :string }
                      }
                    ]
                  }
                }
              }
            }
          end

          it 'generates schema in requestBody for content type' do
            expect(doc_for_api_v2[:paths]['/path/'][:post][:requestBody]).to eql(content: {
              'multipart/form-data' => {
                schema: {
                  type: :object,
                  properties: {
                    myFile: {type: :string, format: :binary},
                    foo: {type: :string}
                  }
                },
                encoding: {
                  myFile: {
                    contentType: "image/png,image/jpeg"
                  }
                }
              }
            })
          end
        end

        context 'with formData multiple file uploads' do
          let(:doc_for_api_v2) do
            {
              paths: {
                '/path/' => {
                  post: {
                    summary: 'Upload files',
                    consumes: ['multipart/form-data'],
                    parameters: [
                      {
                        name: :files,
                        in: :formData,
                        schema: { type: :array, items: { type: :string, format: :binary } }
                      }
                    ]
                  }
                }
              }
            }
          end

          it 'generates schema in requestBody with multipart/form-data' do
            expect(doc_for_api_v2[:paths]['/path/'][:post][:requestBody]).to eql(content: {
              'multipart/form-data' => {
                schema: {
                  type: :object,
                  properties: {
                    files: {type: :array, items: {type: :string, format: :binary}}
                  }
                }
              }
            })
          end
        end

        context 'with formData with multiple parameters' do
          let(:first_param) do
            {
              in: :headers
            }
          end

          let(:doc_for_api_v2) do
            {
              paths: {
                '/path/' => {
                  post: {
                    summary: 'Retrieve Nested Paths',
                    tags: ['nested Paths'],
                    produces: ['application/json'],
                    consumes: ['multipart/form-data'],
                    parameters: [
                      first_param,
                      {
                        name: :file,
                        description: 'the actual file with appropriate content type',
                        in: :formData,
                        schema: {
                          type: :string,
                          format: :binary,
                          required: true
                        },
                        encoding: {
                          contentType: ['text/csv', 'application/json']
                        }
                      },
                      {
                        name: :scheduled_for,
                        description: 'a datetime string in ISO 8601 format',
                        in: :formData,
                        schema: {
                          type: :string,
                          format: 'date-time'
                        }
                      }
                    ]
                  }
                }
              }
            }
          end

          it 'duplicates params in: :formData to requestBody from consumes list' do
            expect(doc_for_api_v2[:paths]['/path/'][:post][:parameters]).to eql([{ in: :headers }])
            request_body = {
              content: {
                'multipart/form-data' => {
                  schema: {
                    type: :object,
                    properties: {
                      file: {
                        description: 'the actual file with appropriate content type',
                        format: :binary,
                        type: :string
                      },
                      scheduled_for: {
                        description: 'a datetime string in ISO 8601 format',
                        format: 'date-time',
                        type: :string
                      }
                    },
                    required: ["file"]
                  },
                  encoding: {
                    file: {
                      contentType: 'text/csv,application/json'
                    }
                  }
                }
              },
              required: true
            }
            expect(doc_for_api_v2[:paths]['/path/'][:post][:requestBody]).to eql(request_body)
          end

          context 'with a requestBody schema defined by reference' do
            let(:first_param) do
              {
                in: :formData,
                schema: {
                  '$ref': '#/components/schemas/BlogPost'
                }
              }
            end

            it 'ignores :formData parameters defined after the requestBody schema is set my reference' do
              expect(doc_for_api_v2[:paths]['/path/'][:post][:requestBody]).to eql(
                content: {
                  'multipart/form-data' => {
                    schema: {
                      '$ref': '#/components/schemas/BlogPost'
                    }
                  }
                }
              )
            end
          end
        end

        context 'with multiple `in: formData` parameters' do
          let(:doc_for_api_v2) do
            {
              paths: {
                '/path/' => {
                  post: {
                    produces: ['application/json'],
                    consumes: ['application/json'],
                    parameters: [
                      {
                        in: :formData,
                        name: :foo,
                        schema: { type: :number }
                      },
                      {
                        in: :formData,
                        name: :bar,
                        schema: { type: :string }
                      }
                    ]
                  }
                }
              }
            }
          end

          it 'formData parameters appear in requestBody' do
            expect(doc_for_api_v2[:paths]['/path/'][:post][:requestBody]).to eql(
              content: {
                'application/json' => {
                  schema: {
                    type: :object,
                    properties: {
                      foo: {
                        type: :number
                      },
                      bar: {
                        type: :string
                      }
                    }
                  }
                }
              }
            )
          end
        end

        after do
          FileUtils.rm_r(openapi_root) if File.exist?(openapi_root)
        end

        context 'with request examples' do
          let(:doc_for_api_v2) do
            {
              paths: {
                '/path/' => {
                  post: {
                    summary: 'Retrieve Nested Paths',
                    tags: ['nested Paths'],
                    produces: ['application/json'],
                    consumes: ['application/json'],
                    parameters: [{
                      in: :formData,
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
            expect(doc_for_api_v2[:paths]['/path/'][:post].keys).to eql([:summary, :tags, :parameters, :requestBody])
          end

          it 'creates requestBody examples' do
            expect(doc_for_api_v2[:paths]['/path/'][:post][:parameters]).to eql([{ in: :headers }])
            expect(doc_for_api_v2[:paths]['/path/'][:post][:requestBody]).to eql(content: {
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
