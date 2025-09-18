# frozen_string_literal: true

# cspell:ignore Bfoo Bbar

require 'rswag/specs/request_factory'
require 'date'

module Rswag
  module Specs
    RSpec.describe RequestFactory do
      subject { RequestFactory.new(metadata, example, config) }

      before do
        allow(config).to receive(:get_openapi_spec).and_return(openapi_spec)
      end

      let(:config) { double('config') }
      let(:example) { MockExample.new({}, {}) }
      let(:metadata) do
        {
          path_item: { template: '/blogs' },
          operation: { verb: :get }
        }
      end
      let(:openapi_spec) { { openapi: '3.0' } }

      MockExample = Struct.new(:request_headers, :request_params)

      describe '#build_request' do
        let(:request) { subject.build_request }

        it 'builds request hash for given example' do
          expect(request[:verb]).to eq(:get)
          expect(request[:path]).to eq('/blogs')
        end

        context "'path' parameters" do
          before do
            metadata[:path_item][:template] = '/blogs/{blog_id}/comments/{id}'
            metadata[:operation][:parameters] = [
              { name: 'blog_id', in: :path, type: :number },
              { name: 'id', in: :path, type: :number }
            ]
          end

          context 'when `name` parameter key is required, but not defined within example group' do
            it 'explicitly warns user about missing parameter, instead of giving generic error' do
              expect { request[:path] }.to raise_error(/parameter key present, but not defined/)
            end
          end

          context 'when `name` is defined' do
            before do
              example.request_params['blog_id'] = 1
              example.request_params['id'] = 2
            end

            it 'builds the path from example values' do
              expect(request[:path]).to eq('/blogs/1/comments/2')
            end
          end
        end

        context "'query' parameters" do
          before do
            metadata[:operation][:parameters] = [
              { name: 'q1', in: :query, schema: { type: :string } },
              { name: 'q2', in: :query, schema: { type: :string } },
              { name: 'q3', in: :query, schema: { type: :string } },
              { name: 'falsey', in: :query, schema: { type: :boolean } }
            ]
            example.request_params['q1'] = 'foo'
            example.request_params['q2'] = 'bar'
            example.request_params['falsey'] = false
          end

          it 'builds the query string from example values' do
            expect(request[:path]).to eq('/blogs?q1=foo&q2=bar&falsey=false')
          end

          context 'when `type` parameter key is present' do
            before do
              metadata[:operation][:parameters] = [
                { name: 'q1', in: :query, type: :string }
              ]
              example.request_params['q1'] = 'baz'
            end

            it 'warns user about unsupported parameter' do
              expect { request[:path] }.to raise_error(/'type' is not supported field for Parameter/)
            end
          end
        end

        context "'query' parameter of format 'datetime'" do
          let(:date_time) { DateTime.new(2001, 2, 3, 4, 5, 6, '-7').to_s }

          before do
            metadata[:operation][:parameters] = [
              { name: 'date_time', in: :query, schema: { type: :string, format: :datetime } }
            ]
            example.request_params['date_time'] = date_time
          end

          it 'formats the datetime properly' do
            expect(request[:path]).to eq('/blogs?date_time=2001-02-03T04%3A05%3A06-07%3A00')
          end

          context 'iso8601 format' do
            let(:date_time) { DateTime.new(2001, 2, 3, 4, 5, 6, '-7').iso8601 }

            it 'is also formatted properly' do
              expect(request[:path]).to eq('/blogs?date_time=2001-02-03T04%3A05%3A06-07%3A00')
            end
          end

          context 'openapi spec >= 3.0.0' do
            let(:openapi_spec) { { swagger: '3.0' } }

            before do
              allow(example).to receive(:date_time).and_return(date_time)
            end

            it 'formats the datetime properly when type is defined in schema' do
              metadata[:operation][:parameters] = [
                { name: 'date_time', in: :query, schema: { type: :string }, format: :datetime }
              ]
              expect(request[:path]).to eq('/blogs?date_time=2001-02-03T04%3A05%3A06-07%3A00')
            end
          end
        end

        context "'query' parameters of type 'object'" do
          let(:things) { { 'foo': 'bar' } }
          let(:openapi_spec) { { openapi: '3.0' } }

          before do
            metadata[:operation][:parameters] = [
              {
                name: 'things', in: :query,
                style: style,
                explode: explode,
                schema: { type: :object, additionalProperties: { type: :string } }
              }
            ]
            example.request_params['things'] = things
          end

          context 'deepObject' do
            let(:style) { :deepObject }
            let(:explode) { true }

            it 'formats as deep object' do
              expect(request[:path]).to eq('/blogs?things%5Bfoo%5D=bar')
            end
          end

          context 'deepObject with nested objects' do
            let(:things) { { 'foo': { 'bar': 'baz' } } }
            let(:style) { :deepObject }
            let(:explode) { true }

            it 'formats as deep object' do
              expect(request[:path]).to eq('/blogs?things%5Bfoo%5D%5Bbar%5D=baz')
            end
          end

          context 'form explode=false' do
            let(:style) { :form }
            let(:explode) { false }

            it 'formats as unexploded form' do
              expect(request[:path]).to eq('/blogs?things=foo,bar')
            end
          end

          context 'form explode=true' do
            let(:style) { :form }
            let(:explode) { true }

            it 'formats as an exploded form' do
              expect(request[:path]).to eq('/blogs?foo=bar')
            end
          end

          context 'form explode=true with nesting and uri encodable output' do
            let(:things) { { 'foo': { 'bar': 'baz' }, 'fo&b': 'x[]?y' } }
            let(:style) { :form }
            let(:explode) { true }

            it 'formats as an exploded form' do
              expect(request[:path]).to eq('/blogs?fo%26b=x%5B%5D%3Fy&foo%5Bbar%5D=baz')
            end
          end
        end

        context "'query' parameters of type 'array'" do
          let(:id) { [3, 4, 5] }
          let(:openapi_spec) { { openapi: '3.0' } }

          before do
            metadata[:operation][:parameters] = [
              {
                name: 'id', in: :query,
                style: style,
                explode: explode,
                schema: { type: :array, items: { type: :integer } }
              }
            ]
            example.request_params['id'] = id
          end

          context 'form' do
            let(:style) { :form }

            context 'exploded' do
              let(:explode) { true }

              it 'formats as exploded form' do
                expect(request[:path]).to eq('/blogs?id=3&id=4&id=5')
              end
            end

            context 'not exploded' do
              let(:explode) { false }

              it 'formats as unexploded form' do
                expect(request[:path]).to eq('/blogs?id=3,4,5')
              end
            end
          end

          context 'spaceDelimited' do
            let(:style) { :spaceDelimited }

            context 'exploded' do
              let(:explode) { true }

              it 'formats as exploded form' do
                expect(request[:path]).to eq('/blogs?id=3&id=4&id=5')
              end
            end

            context 'not exploded' do
              let(:explode) { false }

              it 'formats as unexploded form' do
                expect(request[:path]).to eq('/blogs?id=3%204%205')
              end
            end
          end

          context 'pipeDelimited' do
            let(:style) { :pipeDelimited }

            context 'exploded' do
              let(:explode) { true }

              it 'formats as exploded form' do
                expect(request[:path]).to eq('/blogs?id=3&id=4&id=5')
              end
            end

            context 'not exploded' do
              let(:explode) { false }

              it 'formats as unexploded form' do
                expect(request[:path]).to eq('/blogs?id=3|4|5')
              end
            end
          end
        end

        context "'query' parameters with schema reference" do
          let(:things) { 'foo' }
          let(:openapi_spec) { { openapi: '3.0' } }

          before do
            metadata[:operation][:parameters] = [
              {
                name: 'things', in: :query,
                schema: { '$ref' => '#/components/schemas/FooType' }
              }
            ]
            example.request_params['things'] = things
          end

          it 'builds the query string' do
            expect(request[:path]).to eq('/blogs?things=foo')
          end
        end

        context "'header' parameters" do
          before do
            metadata[:operation][:parameters] = [
              { name: 'Api-Key', in: :header, schema: { type: :string } },
              { name: 'Token', in: :header, schema: { type: :string } }
            ]
            example.request_headers['Api-Key'] = 'foobar'
            example.request_headers['Token'] = 'my_token'
          end

          it 'adds names and example values to headers' do
            expect(request[:headers]).to eq({ 'Api-Key' => 'foobar', 'Token' => 'my_token' })
          end
        end

        context 'optional parameters not provided' do
          before do
            metadata[:operation][:parameters] = [
              { name: 'q1', in: :query, schema: { type: :string }, required: false },
              { name: 'Api-Key', in: :header, schema: { type: :string }, required: false }
            ]
          end

          it 'builds request hash without them' do
            expect(request[:path]).to eq('/blogs')
            expect(request[:headers]).to eq({})
          end
        end

        context 'consumes content' do
          before do
            metadata[:operation][:consumes] = ['application/json', 'application/xml']
          end

          context "no 'Content-Type' provided" do
            it "sets 'CONTENT_TYPE' header to first in list" do
              expect(request[:headers]).to eq('CONTENT_TYPE' => 'application/json')
            end
          end

          context "explicit 'Content-Type' provided" do
            before do
              example.request_headers['Content-Type'] = 'application/xml'
            end

            it "sets 'CONTENT_TYPE' header to example value" do
              expect(request[:headers]).to eq('CONTENT_TYPE' => 'application/xml')
            end
          end

          context 'JSON payload' do
            before do
              metadata[:operation][:parameters] = [{ name: 'comment', in: :body, schema: { type: 'object' } }]
              example.request_params['comment'] = { text: 'Some comment' }
            end

            it "serializes first 'body' parameter to JSON string" do
              expect(request[:payload]).to eq('{"text":"Some comment"}')
            end
          end

          context 'JSON:API payload' do
            before do
              metadata[:operation][:consumes] = ['application/vnd.api+json']
              metadata[:operation][:parameters] = [{ name: 'comment', in: :body, schema: { type: 'object' } }]
              example.request_params['comment'] = { text: 'Some comment' }
            end

            it "serializes first 'body' parameter to JSON object" do
              expect(request[:payload]).to eq('{"text":"Some comment"}')
            end
          end

          context 'missing body parameter' do
            before do
              metadata[:operation][:parameters] = [{ name: 'comment', in: :body, schema: { type: 'object' } }]
            end

            it 'uses the referenced metadata to build the request' do
              expect do
                request[:payload]
              end.to raise_error(Rswag::Specs::MissingParameterError, /Missing parameter 'comment'/)
            end
          end

          context 'form payload' do
            before do
              metadata[:operation][:consumes] = ['multipart/form-data']
              metadata[:operation][:parameters] = [
                { name: 'f1', in: :formData, schema: { type: :string } },
                { name: 'f2', in: :formData, schema: { type: :string } }
              ]
              example.request_params['f1'] = 'foo blah'
              example.request_params['f2'] = 'bar blah'
            end

            it 'sets payload to hash of names and example values' do
              expect(request[:payload]).to eq(
                'f1' => 'foo blah',
                'f2' => 'bar blah'
              )
            end
          end

          context 'plain text payload' do
            before do
              metadata[:operation][:consumes] = ['text/plain']
              metadata[:operation][:parameters] = [{ name: 'comment', in: :body, schema: { type: 'string' } }]
              example.request_params['comment'] = 'plain text comment'
            end

            it 'keeps payload as a raw string data' do
              expect(request[:payload]).to eq('plain text comment')
            end
          end
        end

        context 'produces content' do
          before do
            metadata[:operation][:produces] = ['application/json', 'application/xml']
          end

          context "no 'Accept' value provided" do
            it "sets 'HTTP_ACCEPT' header to first in list" do
              expect(request[:headers]).to eq('HTTP_ACCEPT' => 'application/json')
            end
          end

          context "explicit 'Accept' value provided" do
            before do
              example.request_headers['Accept'] = 'application/xml'
            end

            it "sets 'HTTP_ACCEPT' header to example value" do
              expect(request[:headers]).to eq('HTTP_ACCEPT' => 'application/xml')
            end
          end
        end

        context 'host header' do
          context "explicit 'Host' value provided" do
            before do
              metadata[:operation][:host] = 'swagger.io'
            end

            it "sets 'Host' header" do
              expect(request[:headers]).to eq('HTTP_HOST' => 'swagger.io')
            end
          end

          context "no 'Host' value provided" do
            before do
              metadata[:operation][:host] = nil
            end

            it "does not set 'Host' header" do
              expect(request[:headers]).to eq({})
            end
          end
        end

        context 'basic auth' do
          let(:openapi_spec) { { openapi: '3.0.1' } }

          before do
            openapi_spec[:components] = { securitySchemes: { basic: { type: :basic } } }
            metadata[:operation][:security] = [basic: []]
            example.request_headers['Authorization'] = 'Basic foobar'
          end

          it "sets 'HTTP_AUTHORIZATION' header to example value" do
            expect(request[:headers]).to eq('HTTP_AUTHORIZATION' => 'Basic foobar')
          end
        end

        context 'apiKey' do
          before do
            openapi_spec[:components] =
              { securitySchemes: { api_key: { type: :apiKey, name: 'api_key', in: key_location } } }
            metadata[:operation][:security] = [api_key: []]
          end

          context 'in query' do
            let(:key_location) { :query }

            it 'adds name and example value to the query string' do
              example.request_params['api_key'] = 'foobar'
              expect(request[:path]).to eq('/blogs?api_key=foobar')
            end
          end

          context 'in header' do
            let(:key_location) { :header }

            it 'adds name and example value to the headers' do
              example.request_headers['api_key'] = 'foobar'
              expect(request[:headers]).to eq('api_key' => 'foobar')
            end
          end

          context 'in header with auth param already added' do
            let(:key_location) { :header }

            before do
              metadata[:operation][:parameters] = [
                { name: 'q1', in: :query, schema: { type: :string } },
                { name: 'api_key', in: :header, schema: { type: :string } }
              ]
              example.request_params['q1'] = 'foo'
              example.request_headers['api_key'] = 'foobar'
            end

            it 'adds authorization parameter only once' do
              expect(request[:headers]).to eq('api_key' => 'foobar')
              expect(metadata[:operation][:parameters].size).to eq 2
            end
          end
        end

        context 'oauth2' do
          before do
            openapi_spec[:components] =
              { securitySchemes: { oauth2: { type: :oauth2, flows: { implicit: { scopes: ['read:blogs'] } } } } }
            metadata[:operation][:security] = [oauth2: ['read:blogs']]
            example.request_headers['Authorization'] = 'Bearer foobar'
          end

          it "sets 'HTTP_AUTHORIZATION' header to example value" do
            expect(request[:headers]).to eq('HTTP_AUTHORIZATION' => 'Bearer foobar')
          end
        end

        context 'paired security requirements' do
          before do
            openapi_spec[:components] = {
              securitySchemes: {
                basic: {
                  type: :http,
                  scheme: :basic
                },
                api_key: {
                  type: :apiKey,
                  name: 'api_key',
                  in: :query
                }
              }
            }
            metadata[:operation][:security] = [{ basic: [], api_key: [] }]
            example.request_headers['Authorization'] = 'Basic foobar'
            example.request_params['api_key'] = 'foobar'
          end

          it 'sets both params to example values' do
            expect(request[:headers]).to eq('HTTP_AUTHORIZATION' => 'Basic foobar')
            expect(request[:path]).to eq('/blogs?api_key=foobar')
          end
        end

        context 'path-level parameters' do
          before do
            metadata[:operation][:parameters] = [{ name: 'q1', in: :query, schema: { type: :string } }]
            metadata[:path_item][:parameters] = [{ name: 'q2', in: :query, schema: { type: :string } }]
            example.request_params['q1'] = 'foo'
            example.request_params['q2'] = 'bar'
          end

          it 'populates operation and path level parameters' do
            expect(request[:path]).to eq('/blogs?q1=foo&q2=bar')
          end
        end

        context 'referenced parameters' do
          let(:openapi_spec) { { openapi: '3.0.1' } }

          before do
            openapi_spec[:components] = {
              parameters: { q1: { name: 'q1', in: :query, schema: { type: :string } } }
            }
            metadata[:operation][:parameters] = [{ '$ref' => '#/components/parameters/q1' }]
            example.request_params['q1'] = 'foo'
          end

          it 'uses the referenced metadata to build the request' do
            expect(request[:path]).to eq('/blogs?q1=foo')
          end
        end

        context 'base path' do
          before do
            openapi_spec[:servers] = [{
              url: '{protocol}://{defaultHost}',
              variables: {
                protocol: {
                  default: :https
                },
                defaultHost: {
                  default: 'www.example.com'
                }
              }
            }]
          end

          it 'generates the path' do
            expect(request[:path]).to eq('/blogs')
          end
        end

        context 'global consumes' do
          before { openapi_spec[:consumes] = ['application/xml'] }

          it "defaults 'CONTENT_TYPE' to global value(s)" do
            expect(request[:headers]).to eq('CONTENT_TYPE' => 'application/xml')
          end
        end

        context 'global security requirements' do
          before do
            openapi_spec[:components] = { securitySchemes: { api_key: { type: :apiKey, name: 'api_key', in: :query } } }
            openapi_spec[:security] = [api_key: []]
            example.request_params['api_key'] = 'foobar'
          end

          it 'applies the scheme by default' do
            expect(request[:path]).to eq('/blogs?api_key=foobar')
          end
        end
      end
    end
  end
end
