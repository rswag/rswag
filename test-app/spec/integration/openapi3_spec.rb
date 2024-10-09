require 'swagger_helper'
require 'rswag/specs/swagger_formatter'

# This spec file validates OpenAPI output generated by spec metadata.
# Specifically here, we look at OpenApi 3 as documented at
# https://swagger.io/docs/specification/about/

Metadata = Struct.new(:metadata)
Group = Struct.new(:group)

RSpec.describe 'Generated OpenApi', type: :request, openapi_spec: 'v3/openapi.json' do
  before do |example|
    output = double('output').as_null_object
    openapi_root = File.expand_path('tmp/swagger', __dir__)
    config = double('config', openapi_root: openapi_root, get_openapi_spec: openapi_spec)
    formatter = Rswag::Specs::SwaggerFormatter.new(output, config)

    example_group = Group.new(Metadata.new(example.metadata))
    formatter.example_group_finished(example_group)
  end

  # Framework definition, to be overridden for contexts
  let(:openapi_spec) do
    { # That which would be defined in swagger_helper.rb
      openapi: api_openapi,
      info: {},
      servers: api_servers,
      produces: api_produces,
      components: api_components
    }
  end
  let(:api_openapi) { '3.0.3' }
  let(:api_servers) {[{ url: "https://api.example.com/foo" }]}
  let(:api_produces) { ['application/json'] }
  let(:api_components) { {} }

  describe 'Basic Structure'

  describe 'API Server and Base Path' do
    path '/stubs' do
      get 'a summary' do
        tags 'Server and Path'

        response '200', 'OK' do
          run_test!

          it 'lists server' do
            tree = openapi_spec.dig(:servers)
            expect(tree).to eq([
              { url: "https://api.example.com/foo" }
            ])
          end

          context "multiple" do
            let(:api_servers) {[
              { url: "https://api.example.com/foo" },
              { url: "http://api.example.com/foo" },
            ]}

            it 'lists servers' do
              tree = openapi_spec.dig(:servers)
              expect(tree).to eq([
                { url: "https://api.example.com/foo" },
                { url: "http://api.example.com/foo" }
              ])
            end
          end

          context "with variables" do
            let(:api_servers) {[{
              url: "https://{defaultHost}/foo",
              variables: {
                defaultHost: {
                  default: "api.example.com"
                }
              }
            }]}

            it 'lists server and variables' do
              tree = openapi_spec.dig(:servers)
              expect(tree).to eq([{
                url: "https://{defaultHost}/foo",
                variables: {
                  defaultHost: {
                    default: "api.example.com"
                  }
                }
              }])
            end
          end

          # TODO: Enum variables, defaults, override at path/operation
        end
      end
    end
  end

  describe 'Media Types' do
    path '/stubs' do
      get 'a summary' do
        tags 'Media Types'

        response '200', 'OK' do
          run_test!

          it 'declares output as application/json' do
            pending "Not yet implemented?"
            tree = openapi_spec.dig(:paths, "/stubs", :get, :responses, '200', :content)
            expect(tree).to have_key('application/json')
          end
        end
      end
    end
  end

  describe 'Paths and Operations'

  describe 'Parameter Serialization' do
    describe 'Path Parameters' do
      path '/stubs/{a_param}' do
        get 'a summary' do
          tags 'Parameter Serialization: Query String'
          produces 'application/json'

          parameter(
            name: 'a_param',
            in: :path,
          )
          let(:a_param) { "42" }

          response '200', 'OK' do
            run_test!

            it 'declares parameter in path' do
              tree = openapi_spec.dig(:paths, "/stubs/{a_param}", :get, :parameters)
              expect(tree.first[:name]).to eq('a_param')
              expect(tree.first[:in]).to eq(:path)
            end

            it 'declares path parameters as required' do
              tree = openapi_spec.dig(:paths, "/stubs/{a_param}", :get, :parameters)
              expect(tree.first[:required]).to eq(true)
            end
          end
        end
      end
    end

    describe 'Query Parameters' do
      path '/stubs' do
        get 'a summary' do
          tags 'Parameter Serialization: Query String'
          produces 'application/json'

          parameter(
            name: 'a_param',
            in: :query,
          )
          let(:a_param) { "a foo" }

          response '200', 'OK' do
            run_test!

            it 'declares parameter in query string' do
              tree = openapi_spec.dig(:paths, "/stubs", :get, :parameters)
              expect(tree.first[:name]).to eq('a_param')
              expect(tree.first[:in]).to eq(:query)
            end
          end

          # TODO: Serialization (form/spaceDelimited/pipeDelimited/deepObject)
        end
      end
    end

    # TODO: Header
    # TODO: Cookie
    # TODO: Default values
    # TODO: Enum
    # TODO: Constant
    # TODO: Empty/Nullable
    # TODO: Examples
    # TODO: Deprecated
    # TODO: Common Parameters
  end

  describe 'Request Body' do
    path '/stubs' do
      post 'body is required' do
        tags 'Media Types'
        consumes 'multipart/form-data'
        parameter name: :file, :in => :formData, :type => :file, required: true

        let(:file) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/thumbnail.png")) }

        response '200', 'OK' do
          run_test!

          it 'declares requestBody is required' do
            pending "This output is massaged in SwaggerFormatter#stop, and isn't quite ready here to assert"
            tree = openapi_spec.dig(:paths, "/stubs", :post, :requestBody)
            expect(tree[:required]).to eq(true)
          end
        end
      end
    end
  end

  describe 'Responses'
  describe 'Data Models (Schemas)'
  describe 'Examples'
  describe 'Authentication'
  describe 'Links'
  describe 'Callbacks'
  describe 'Components Section'
  describe 'Using $ref'
  describe 'Grouping Operations with Tags'
end
