# frozen_string_literal: true

# cspell:ignore Bfoo Bbar

require 'rswag/specs/request_factory'

module Rswag
  module Specs
    RSpec.describe RequestFactory do
      subject { RequestFactory.new(config) }

      before do
        allow(config).to receive(:get_openapi_spec).and_return(openapi_spec)
      end
      let(:config) { double('config') }
      let(:openapi_spec) { { swagger: '2.0' } }
      let(:example) { double('example') }
      let(:metadata) do
        {
          path_item: { template: '/blogs' },
          operation: { verb: :get }
        }
      end

      describe '#build_request(metadata, example)' do
        let(:request) { subject.build_request(metadata, example) }

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
              allow(example).to receive(:blog_id).and_return(1)
              allow(example).to receive(:id).and_return(2)
            end

            it 'builds the path from example values' do
              expect(request[:path]).to eq('/blogs/1/comments/2')
            end

            context 'when `getter is defined`' do
              before do
                metadata[:operation][:parameters] = [
                  { name: 'blog_id', in: :path, type: :number },
                  { name: 'id', in: :path, type: :number, getter: :param_id }
                ]

                allow(example).to receive(:param_id).and_return(123)
              end

              it 'builds the path using getter method' do
                expect(request[:path]).to eq('/blogs/1/comments/123')
              end
            end
          end
        end

        context "'query' parameters" do
          before do
            metadata[:operation][:parameters] = [
              { name: 'q1', in: :query, type: :string },
              { name: 'q2', in: :query, type: :string }
            ]
            allow(example).to receive(:q1).and_return('foo')
            allow(example).to receive(:q2).and_return('bar')
          end

          it 'builds the query string from example values' do
            expect(request[:path]).to eq('/blogs?q1=foo&q2=bar')
          end

          context 'when `getter is defined`' do
            before do
              metadata[:operation][:parameters] << {
                name: 'status', in: :query, type: :string, getter: :q3_status
              }

              allow(example).to receive(:status).and_return(nil)
              allow(example).to receive(:q3_status).and_return(123)
            end

            it 'builds the query string using getter method' do
              expect(request[:path]).to eq('/blogs?q1=foo&q2=bar&status=123')
            end
          end
        end

        context "'query' parameters of type 'array'" do
          before do
            metadata[:operation][:parameters] = [
              { name: 'things', in: :query, type: :array, collectionFormat: collection_format },
              { name: 'numbers', in: :query, type: :array, collectionFormat: collection_format, getter: :magic_numbers },
            ]
            allow(example).to receive(:things).and_return(['foo', 'bar'])
            allow(example).to receive(:magic_numbers).and_return([0, 1])
            expect(example).not_to receive(:numbers)
          end

          context 'collectionFormat = csv' do
            let(:collection_format) { :csv }
            it 'formats as comma separated values' do
              expect(request[:path]).to eq('/blogs?things=foo,bar&numbers=0,1')
            end
          end

          context 'collectionFormat = ssv' do
            let(:collection_format) { :ssv }
            it 'formats as space separated values' do
              expect(request[:path]).to eq('/blogs?things=foo bar&numbers=0 1')
            end
          end

          context 'collectionFormat = tsv' do
            let(:collection_format) { :tsv }
            it 'formats as tab separated values' do
              expect(request[:path]).to eq('/blogs?things=foo\tbar&numbers=0\t1')
            end
          end

          context 'collectionFormat = pipes' do
            let(:collection_format) { :pipes }
            it 'formats as pipe separated values' do
              expect(request[:path]).to eq('/blogs?things=foo|bar&numbers=0|1')
            end
          end

          context 'collectionFormat = multi' do
            let(:collection_format) { :multi }
            it 'formats as multiple parameter instances' do
              expect(request[:path]).to eq('/blogs?things=foo&things=bar&numbers=0&numbers=1')
            end
          end
        end

        context "'query' parameter of format 'datetime'" do
          let(:date_time) { DateTime.new(2001, 2, 3, 4, 5, 6, '-7').to_s  }

          before do
            metadata[:operation][:parameters] = [
              { name: 'date_time', in: :query, type: :string, format: :datetime, }
            ]
            allow(example).to receive(:date_time).and_return(date_time)
          end

          it 'formats the datetime properly' do
            expect(request[:path]).to eq('/blogs?date_time=2001-02-03T04%3A05%3A06-07%3A00')
          end

          context "iso8601 format" do
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
                { name: 'date_time', in: :query, schema: { type: :string }, format: :datetime, }
              ]
              expect(request[:path]).to eq('/blogs?date_time=2001-02-03T04%3A05%3A06-07%3A00')
            end
          end
        end

        context "'query' parameters of type 'object'" do
          let(:things) { {'foo': 'bar'} }
          let(:openapi_spec) { { swagger: '3.0' } }

          before do
            metadata[:operation][:parameters] = [
              {
                name: 'things', in: :query,
                style: style,
                explode: explode,
                schema: { type: :object, additionalProperties: { type: :string } }
              }
            ]
            allow(example).to receive(:things).and_return(things)
          end

          context 'deepObject' do
            let(:style) { :deepObject }
            let(:explode) { true }
            it 'formats as deep object' do
              expect(request[:path]).to eq('/blogs?things%5Bfoo%5D=bar')
            end
          end

          context 'deepObject with nested objects' do
            let(:things) { {'foo': { 'bar': 'baz' }} }
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
            let(:things) { {'foo': { 'bar': 'baz' }, 'fo&b': 'x[]?y'} }
            let(:style) { :form }
            let(:explode) { true }
            it 'formats as an exploded form' do
              expect(request[:path]).to eq('/blogs?fo%26b=x%5B%5D%3Fy&foo%5Bbar%5D=baz')
            end
          end
        end

        context "'query' parameters of type 'array'" do
          let(:id) { [3, 4, 5] }
          let(:openapi_spec) { { swagger: '3.0' } }

          before do
            metadata[:operation][:parameters] = [
              {
                name: 'id', in: :query,
                style: style,
                explode: explode,
                schema: { type: :array, items: { type: :integer } }
              }
            ]
            allow(example).to receive(:id).and_return(id)
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

          context "spaceDelimited" do
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

          context "pipeDelimited" do
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
          let(:openapi_spec) { { swagger: '3.0' } }

          before do
            metadata[:operation][:parameters] = [
              {
                name: 'things', in: :query,
                schema: { '$ref' => '#/components/schemas/FooType' }
              }
            ]
            allow(example).to receive(:things).and_return(things)
          end

          it 'builds the query string' do
            expect(request[:path]).to eq('/blogs?things=foo')
          end
        end

        context "'header' parameters" do
          before do
            metadata[:operation][:parameters] = [
              { name: 'Api-Key', in: :header, type: :string },
              { name: 'Token', getter: :token_param, in: :header, type: :string }
            ]
            allow(example).to receive(:'Api-Key').and_return('foobar')
            allow(example).to receive(:'token_param').and_return('my_token')
          end

          it 'adds names and example values to headers' do
            expect(request[:headers]).to eq({ 'Api-Key' => 'foobar', 'Token' => 'my_token' })
          end
        end

        context 'optional parameters not provided' do
          before do
            metadata[:operation][:parameters] = [
              { name: 'q1', in: :query, type: :string, required: false },
              { name: 'Api-Key', in: :header, type: :string, required: false }
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
              allow(example).to receive(:'Content-Type').and_return('application/xml')
            end

            it "sets 'CONTENT_TYPE' header to example value" do
              expect(request[:headers]).to eq('CONTENT_TYPE' => 'application/xml')
            end
          end

          context 'JSON payload' do
            before do
              metadata[:operation][:parameters] = [{ name: 'comment', in: :body, schema: { type: 'object' } }]
              allow(example).to receive(:comment).and_return(text: 'Some comment')
            end

            it "serializes first 'body' parameter to JSON string" do
              expect(request[:payload]).to eq('{"text":"Some comment"}')
            end
          end

          context 'JSON:API payload' do
            before do
              metadata[:operation][:consumes] = 'application/vnd.api+json'
              metadata[:operation][:parameters] = [{ name: 'comment', in: :body, schema: { type: 'object' } }]
              allow(example).to receive(:comment).and_return(text: 'Some comment')
            end

            it "serializes first 'body' parameter to JSON object" do
              expect(request[:payload]).to eq(text: 'Some comment')
            end
          end

          context 'missing body parameter' do
            before do
              metadata[:operation][:parameters] = [{ name: 'comment', in: :body, schema: { type: 'object' } }]
              allow(example).to receive(:comment).and_raise(NoMethodError, "undefined method 'comment'")
              allow(example).to receive(:respond_to?).with(:'Content-Type')
              allow(example).to receive(:respond_to?).with('comment').and_return(false)
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
                { name: 'f1', in: :formData, type: :string },
                { name: 'f2', in: :formData, type: :string }
              ]
              allow(example).to receive(:f1).and_return('foo blah')
              allow(example).to receive(:f2).and_return('bar blah')
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
              metadata[:operation][:parameters] = [{ name: 'comment', in: :body, type: 'string' }]
              allow(example).to receive(:comment).and_return('plain text comment')
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
              allow(example).to receive(:Accept).and_return('application/xml')
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
          context 'swagger 2.0' do
            before do
              openapi_spec[:securityDefinitions] = { basic: { type: :basic } }
              metadata[:operation][:security] = [basic: []]
              allow(example).to receive(:Authorization).and_return('Basic foobar')
            end

            it "sets 'HTTP_AUTHORIZATION' header to example value" do
              expect(request[:headers]).to eq('HTTP_AUTHORIZATION' => 'Basic foobar')
            end
          end

          context 'openapi 3.0.1' do
            let(:openapi_spec) { { openapi: '3.0.1' } }
            before do
              openapi_spec[:components] = { securitySchemes: { basic: { type: :basic } } }
              metadata[:operation][:security] = [basic: []]
              allow(example).to receive(:Authorization).and_return('Basic foobar')
            end

            it "sets 'HTTP_AUTHORIZATION' header to example value" do
              expect(request[:headers]).to eq('HTTP_AUTHORIZATION' => 'Basic foobar')
            end
          end

          context 'openapi 3.0.1 upgrade notice' do
            let(:openapi_spec) { { openapi: '3.0.1' } }
            before do
              allow(Rswag::Specs.deprecator).to receive(:warn)
              openapi_spec[:securityDefinitions] = { basic: { type: :basic } }
              metadata[:operation][:security] = [basic: []]
              allow(example).to receive(:Authorization).and_return('Basic foobar')
            end

            it 'warns the user to upgrade' do
              expect(request[:headers]).to eq('HTTP_AUTHORIZATION' => 'Basic foobar')
              expect(Rswag::Specs.deprecator).to have_received(:warn)
                .with('Rswag::Specs: WARNING: securityDefinitions is replaced in OpenAPI3! Rename to components/securitySchemes (in swagger_helper.rb)')
              expect(openapi_spec[:components]).to have_key(:securitySchemes)
            end
          end
        end

        context 'apiKey' do
          before do
            openapi_spec[:securityDefinitions] = { apiKey: { type: :apiKey, name: 'api_key', in: key_location } }
            metadata[:operation][:security] = [apiKey: []]
            allow(example).to receive(:api_key).and_return('foobar')
          end

          context 'in query' do
            let(:key_location) { :query }

            it 'adds name and example value to the query string' do
              expect(request[:path]).to eq('/blogs?api_key=foobar')
            end
          end

          context 'in header' do
            let(:key_location) { :header }

            it 'adds name and example value to the headers' do
              expect(request[:headers]).to eq('api_key' => 'foobar')
            end
          end

          context 'in header with auth param already added' do
            let(:key_location) { :header }
            before do
              metadata[:operation][:parameters] = [
                { name: 'q1', in: :query, type: :string },
                { name: 'api_key', in: :header, type: :string }
              ]
              allow(example).to receive(:q1).and_return('foo')
              allow(example).to receive(:api_key).and_return('foobar')
            end

            it 'adds authorization parameter only once' do
              expect(request[:headers]).to eq('api_key' => 'foobar')
              expect(metadata[:operation][:parameters].size).to eq 2
            end
          end
        end

        context 'oauth2' do
          before do
            openapi_spec[:securityDefinitions] = { oauth2: { type: :oauth2, scopes: ['read:blogs'] } }
            metadata[:operation][:security] = [oauth2: ['read:blogs']]
            allow(example).to receive(:Authorization).and_return('Bearer foobar')
          end

          it "sets 'HTTP_AUTHORIZATION' header to example value" do
            expect(request[:headers]).to eq('HTTP_AUTHORIZATION' => 'Bearer foobar')
          end
        end

        context 'paired security requirements' do
          before do
            openapi_spec[:securityDefinitions] = {
              basic: { type: :basic },
              api_key: { type: :apiKey, name: 'api_key', in: :query }
            }
            metadata[:operation][:security] = [{ basic: [], api_key: [] }]
            allow(example).to receive(:Authorization).and_return('Basic foobar')
            allow(example).to receive(:api_key).and_return('foobar')
          end

          it 'sets both params to example values' do
            expect(request[:headers]).to eq('HTTP_AUTHORIZATION' => 'Basic foobar')
            expect(request[:path]).to eq('/blogs?api_key=foobar')
          end
        end

        context 'path-level parameters' do
          before do
            metadata[:operation][:parameters] = [{ name: 'q1', in: :query, type: :string }]
            metadata[:path_item][:parameters] = [{ name: 'q2', in: :query, type: :string }]
            allow(example).to receive(:q1).and_return('foo')
            allow(example).to receive(:q2).and_return('bar')
          end

          it 'populates operation and path level parameters' do
            expect(request[:path]).to eq('/blogs?q1=foo&q2=bar')
          end
        end

        context 'referenced parameters' do
          context 'swagger 2.0' do
            before do
              openapi_spec[:parameters] = { q1: { name: 'q1', in: :query, type: :string } }
              metadata[:operation][:parameters] = [{ '$ref' => '#/parameters/q1' }]
              allow(example).to receive(:q1).and_return('foo')
            end

            it 'uses the referenced metadata to build the request' do
              expect(request[:path]).to eq('/blogs?q1=foo')
            end
          end

          context 'openapi 3.0.1' do
            let(:openapi_spec) { { openapi: '3.0.1' } }
            before do
              openapi_spec[:components] = { parameters: { q1: { name: 'q1', in: :query, type: :string } } }
              metadata[:operation][:parameters] = [{ '$ref' => '#/components/parameters/q1' }]
              allow(example).to receive(:q1).and_return('foo')
            end

            it 'uses the referenced metadata to build the request' do
              expect(request[:path]).to eq('/blogs?q1=foo')
            end
          end

          context 'openapi 3.0.1 upgrade notice' do
            let(:openapi_spec) { { openapi: '3.0.1' } }
            before do
              allow(Rswag::Specs.deprecator).to receive(:warn)
              openapi_spec[:parameters] = { q1: { name: 'q1', in: :query, type: :string } }
              metadata[:operation][:parameters] = [{ '$ref' => '#/parameters/q1' }]
              allow(example).to receive(:q1).and_return('foo')
            end

            it 'warns the user to upgrade' do
              expect(request[:path]).to eq('/blogs?q1=foo')
              expect(Rswag::Specs.deprecator).to have_received(:warn)
                .with('Rswag::Specs: WARNING: #/parameters/ refs are replaced in OpenAPI3! Rename to #/components/parameters/')
              expect(Rswag::Specs.deprecator).to have_received(:warn)
                .with('Rswag::Specs: WARNING: parameters is replaced in OpenAPI3! Rename to components/parameters (in swagger_helper.rb)')
            end
          end
        end

        context 'base path' do
          context 'openapi 2.0' do
            before { openapi_spec[:basePath] = '/api' }

            it 'prepends to the path' do
              expect(request[:path]).to eq('/api/blogs')
            end
          end

          context 'openapi 3.0' do
            before do
              openapi_spec[:servers] = [{
                :url => "{protocol}://{defaultHost}",
                :variables => {
                  :protocol => {
                    :default => :https
                  },
                  :defaultHost => {
                    :default => "www.example.com"
                  }
                }
              }]
            end

            it 'generates the path' do
              expect(request[:path]).to eq('/blogs')
            end
          end

          context 'openapi 3.0 with old config' do
            let(:openapi_spec) { {:openapi => '3.0', :basePath => '/blogs' } }

            before do
              allow(Rswag::Specs.deprecator).to receive(:warn)
            end

            it 'generates the path' do
              expect(request[:headers]).to eq({})
              expect(Rswag::Specs.deprecator).to have_received(:warn)
                .with('Rswag::Specs: WARNING: basePath is replaced in OpenAPI3! Update your swagger_helper.rb')
            end
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
            openapi_spec[:securityDefinitions] = { apiKey: { type: :apiKey, name: 'api_key', in: :query } }
            openapi_spec[:security] = [apiKey: []]
            allow(example).to receive(:api_key).and_return('foobar')
          end

          it 'applies the scheme by default' do
            expect(request[:path]).to eq('/blogs?api_key=foobar')
          end
        end
      end
    end
  end
end
