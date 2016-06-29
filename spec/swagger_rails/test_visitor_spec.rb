require 'rails_helper'
require 'swagger_rails/test_visitor'

module SwaggerRails

  describe TestVisitor do
    let(:test) { spy('test') }
    let(:swagger_doc) { {} }
    subject { described_class.new(swagger_doc) }

    describe '#submit_request!' do
      before { subject.submit_request!(test, metadata) }

      context 'always' do
        let(:metadata) do
          {
            path_template: '/resource',
            http_verb: :get,
            parameters: []
          }
        end

        it 'dispatches the request to the provided test object' do
          expect(test).to have_received(:get)
        end
      end

      context 'given path parameters' do
        let(:metadata) do
          allow(test).to receive(:id).and_return(1)
          return {
            path_template: '/resource/{id}',
            http_verb: :get,
            parameters: [ { name: 'id', :in => :path, type: 'string' } ]
          }
        end

        it 'builds the path from values on the test object' do
          expect(test).to have_received(:get).with('/resource/1', {}, {})
        end
      end

      context 'given body parameters' do
        let(:metadata) do
          allow(test).to receive(:resource).and_return({ foo: 'bar' })
          return {
            path_template: '/resource',
            http_verb: :post,
            consumes: [ 'application/json' ],
            parameters: [ { name: 'resource', :in => :body, schema: { type: 'object' } } ]
          }
        end

        it 'builds a body from value on the test object' do
          expect(test).to have_received(:post).with(
            '/resource',
            "{\"foo\":\"bar\"}",
            { 'CONTENT_TYPE' => 'application/json' }
          )
        end
      end

      context 'given query parameters' do
        let(:metadata) do
          allow(test).to receive(:type).and_return('foo')
          return {
            path_template: '/resource',
            http_verb: :get,
            parameters: [ { name: 'type', :in => :query, type: 'string' } ]
          }
        end

        it 'builds query params from values on the test object' do
          expect(test).to have_received(:get).with('/resource', { 'type' => 'foo' }, {})
        end
      end

      context 'given header parameters' do
        let(:metadata) do
          allow(test).to receive(:date).and_return('2000-01-01')
          return {
            path_template: '/resource',
            http_verb: :get,
            produces: [ 'application/json' ],
            parameters: [ { name: 'Date', :in => :header, type: 'string' } ]
          }
        end

        it 'builds request headers from values on the test object' do
          expect(test).to have_received(:get).with(
            '/resource',
            {},
            { 'Date' => '2000-01-01', 'ACCEPT' => 'application/json' }
          )
        end
      end

      context 'when a basePath is provided' do
        let(:swagger_doc) { { basePath: '/api' } }
        let(:metadata) do
          {
            path_template: '/resource',
            http_verb: :get,
            parameters: []
          }
        end

        it 'prepends the basePath to the request path' do
          expect(test).to have_received(:get).with('/api/resource', {}, {})
        end
      end
    end

    describe '#assert_response' do
      before { subject.assert_response!(test, metadata) }
      let(:metadata) { { response_code: '200' } }

      it 'dispatches the assert to the provided test object' do
        expect(test).to have_received(:assert_response).with(200)
      end
    end
  end
end
