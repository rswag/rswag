# frozen_string_literal: true

require 'rswag/specs/openapi_formatter'
require 'ostruct'

module Rswag
  module Specs
    RSpec.describe OpenapiFormatter do
      let(:config) do
        instance_double(
          ::Rswag::Specs::Configuration,
          openapi_root: File.expand_path('tmp/openapi', __dir__)
        )
      end

      describe '#example_group_finished(notification)' do
        subject(:resulting_spec) do
          notification = OpenStruct.new(group: OpenStruct.new(metadata: api_metadata))
          described_class.new(nil, config).example_group_finished(notification)
          openapi_spec
        end

        before do
          allow(config).to receive(:get_openapi_spec).and_return(openapi_spec)
        end

        let(:api_metadata) do
          operation = { verb: :post, summary: 'Creates a blog', parameters: [{ type: :string }] }
          {
            path_item: { template: '/blogs', parameters: [{ type: :string }] },
            operation: operation,
            response: {
              code: '201',
              description: 'blog created',
              headers: { 'Accept' => { type: :string } },
              schema: { '$ref' => '#/components/schemas/blog' }
            }
          }
        end

        context 'with the document tag set to false' do
          let(:openapi_spec) { { openapi: '3.0' } }

          before { api_metadata[:document] = false }

          it 'does not update the openapi doc' do
            expect(resulting_spec).to match({ openapi: '3.0' })
          end
        end

        context 'with the document tag set to anything but false' do
          let(:openapi_spec) { { openapi: '3.0' } }

          # anything works, including its absence when specifying responses.
          before { api_metadata[:document] = nil }

          it 'converts to openapi and merges into the corresponding openapi doc' do
            expect(resulting_spec).to match(
              {
                openapi: '3.0',
                paths: {
                  '/blogs' => {
                    parameters: [{ schema: { type: :string } }],
                    post: {
                      parameters: [{ schema: { type: :string } }],
                      summary: 'Creates a blog',
                      responses: {
                        '201' => {
                          description: 'blog created',
                          headers: { 'Accept' => { schema: { type: :string } } }
                        }
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
        subject(:result_v2_paths) do
          described_class.new(nil, config).stop
          doc_for_api_v2[:paths]
        end

        before do
          FileUtils.rm_r(config.openapi_root) if File.exist?(config.openapi_root)
          allow(config).to receive_messages(
            openapi_specs: {
              'v1/openapi.json' => { info: { version: 'v1' } },
              'v2/openapi.json' => doc_for_api_v2
            },
            openapi_format: :json
          )
        end

        let(:doc_for_api_v2) { { info: { version: 'v2' } } }

        after do
          FileUtils.rm_r(config.openapi_root) if File.exist?(config.openapi_root)
        end

        context 'with default format' do
          it 'writes the openapi_spec(s) to file', :aggregate_failures do
            described_class.new(nil, config).stop

            expect(File).to exist("#{config.openapi_root}/v1/openapi.json")
            expect(File).to exist("#{config.openapi_root}/v2/openapi.json")
            expect { JSON.parse(File.read("#{config.openapi_root}/v2/openapi.json")) }.not_to raise_error
          end
        end

        context 'with yaml format' do
          before { allow(config).to receive_messages(openapi_format: :yaml) }

          it 'writes the openapi_spec(s) as yaml', :aggregate_failures do
            described_class.new(nil, config).stop

            expect(File).to exist("#{config.openapi_root}/v1/openapi.json")
            expect { JSON.parse(File.read("#{config.openapi_root}/v1/openapi.json")) }.to raise_error(JSON::ParserError)
            # Psych::DisallowedClass would be raised if we do not pre-process ruby symbols
            expect { YAML.safe_load(File.read("#{config.openapi_root}/v1/openapi.json")) }.not_to raise_error
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
                      name: 'Accept',
                      in: :headers,
                      type: :string
                    }],
                    security: [{ # Must provide both my_auth and oauth2_with_scopes
                      my_auth: [],
                      oauth2_with_scopes: %i[scope1 scope2]
                    }, { # or can auth with only auth_with_this
                      auth_with_this: []
                    }]
                  }
                }
              }
            }
          end

          it 'removes remaining consumes/produces' do
            expect(result_v2_paths['/path/'][:get].keys).to include(:summary, :tags, :parameters, :requestBody,
                                                                    :security)
          end

          it 'params in: :formData appear in requestBody' do
            expect(result_v2_paths['/path/'][:get]).to include(
              parameters: [{ in: :headers, name: 'Accept', schema: { type: :string } }],
              requestBody: {
                content: {
                  'application/xml' => { schema: { foo: :bar } },
                  'application/json' => { schema: { foo: :bar } }
                }
              }
            )
          end

          it 'adds security to operation' do
            expect(result_v2_paths['/path/'][:get][:security]).to eql(
              [
                { my_auth: [], oauth2_with_scopes: %i[scope1 scope2] },
                { auth_with_this: [] }
              ]
            )
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
                    }, {
                      name: 'Accept',
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
                      schema: { '$ref': '#/components/schemas/BlogPost' },
                      required: true
                    }]
                  }
                }
              }
            }
          end

          it 'removes remaining consumes/produces' do
            expect(result_v2_paths['/path/'][:post].keys).to eql(%i[summary tags parameters requestBody])
          end

          it 'duplicates params in: :formData to requestBody from consumes list' do
            expect(result_v2_paths['/path/'][:post]).to include(
              parameters: [{ in: :headers, name: 'Accept' }],
              requestBody: { content: { 'multipart/form-data' => { schema: { type: :string } } } }
            )
          end

          it 'supports legacy body parameters' do
            expect(result_v2_paths['/support_legacy_body/'][:post]).to include(
              parameters: [],
              requestBody: {
                content: { 'application/json' => { schema: { type: :object } } },
                required: true
              }
            )
          end

          it 'supports legacy body parameters with name' do
            expect(result_v2_paths['/support_legacy_body_param_with_name/'][:post]).to include(
              parameters: [],
              requestBody: {
                content: { 'application/json' => { schema: { '$ref': '#/components/schemas/BlogPost' } } },
                required: true
              }
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
            expect(result_v2_paths['/path/'][:get][:parameters]).to match(
              [{
                in: :query,
                name: :foo,
                schema: { enum: %w[bar baz] },
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
            expect(result_v2_paths['/path/'][:post][:requestBody]).to eql(
              content: {
                'image/png' => { schema: { type: :string, format: :binary } },
                'application/octet-stream' => { schema: { type: :string, format: :binary } }
              }
            )
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
                        encoding: { contentType: ['image/png', 'image/jpeg'] }
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
            expect(result_v2_paths['/path/'][:post][:requestBody]).to eql(
              content: {
                'multipart/form-data' => {
                  schema: {
                    type: :object,
                    properties: {
                      myFile: { type: :string, format: :binary },
                      foo: { type: :string }
                    }
                  },
                  encoding: { myFile: { contentType: 'image/png,image/jpeg' } }
                }
              }
            )
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
            expect(result_v2_paths['/path/'][:post][:requestBody]).to eql(
              content: {
                'multipart/form-data' => {
                  schema: {
                    type: :object,
                    properties: {
                      files: { type: :array,
                               items: { type: :string, format: :binary } }
                    }
                  }
                }
              }
            )
          end
        end

        context 'with formData with multiple parameters' do
          let(:first_param) { { in: :headers } }

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
            expect(result_v2_paths['/path/'][:post]).to include(
              parameters: [{ in: :headers }],
              requestBody: {
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
                      required: ['file']
                    },
                    encoding: { file: { contentType: 'text/csv,application/json' } }
                  }
                },
                required: true
              }
            )
          end

          context 'with a requestBody schema defined by reference' do
            let(:first_param) do
              {
                in: :formData,
                schema: { '$ref': '#/components/schemas/BlogPost' }
              }
            end

            it 'ignores :formData parameters defined after the requestBody schema is set my reference' do
              expect(result_v2_paths['/path/'][:post][:requestBody]).to eql(
                content: {
                  'multipart/form-data' => {
                    schema: { '$ref': '#/components/schemas/BlogPost' }
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
            expect(result_v2_paths['/path/'][:post][:requestBody]).to eql(
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
                    }, {
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
                    ]
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
            expect(result_v2_paths['/path/'][:post].keys).to eql(%i[summary tags parameters requestBody])
          end

          it 'creates requestBody examples' do
            expect(result_v2_paths['/path/'][:post]).to include(
              parameters: [{ in: :headers }],
              requestBody: {
                content: {
                  'application/json' => {
                    schema: { '$ref': '#/components/schemas/BlogPost' },
                    examples: {
                      'basic' => {
                        value: { some_field: 'Foo' },
                        summary: 'An example'
                      },
                      'another_basic' => {
                        value: { some_field: 'Bar' },
                        summary: 'Retrieve Nested Paths'
                      }
                    }
                  }
                }
              }
            )
          end
        end
      end
    end
  end
end
