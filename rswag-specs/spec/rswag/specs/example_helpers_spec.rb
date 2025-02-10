# frozen_string_literal: true

require 'rswag/specs/example_helpers'

module Rswag
  module Specs
    RSpec.describe ExampleHelpers do
      mock_example = Struct.new(:request_headers, :request_params)
      subject { mock_example.new({}, {}) }

      before do
        subject.extend(ExampleHelpers)
        allow(Rswag::Specs).to receive(:config).and_return(config)
        allow(config).to receive(:get_openapi_spec).and_return(openapi_spec)
      end
      let(:config) { double('config') }
      let(:openapi_spec) do
        {
          openapi: '3.0',
          components: {
            securitySchemes: {
              api_key: {
                type: :apiKey,
                name: 'api_key',
                in: :query
              }
            }
          }
        }
      end

      let(:metadata) do
        {
          path_item: { template: '/blogs/{blog_id}/comments/{id}' },
          operation: {
            verb: :put,
            summary: 'Updates a blog',
            consumes: ['application/json'],
            parameters: [
              { name: 'blog_id', in: :path, schema: { type: 'integer' } },
              { name: 'id', in: :path, schema: { type: 'integer' } },
              { name: 'q1', in: :query, schema: { type: 'string' } },
              { name: 'blog', in: :body, schema: { type: 'object' } }
            ],
            security: [
              { api_key: [] }
            ]
          }
        }
      end

      describe '#submit_request(metadata)' do
        before do
          subject.request_params['blog_id'] = 1
          subject.request_params['id'] = 2
          subject.request_params['q1'] = 'foo'
          subject.request_params['api_key'] = 'fooKey'
          subject.request_params['blog'] = { text: 'Some comment' }
          allow(subject).to receive(:put)
          subject.submit_request(metadata)
        end

        it "submits a request built from metadata and 'let' values" do
          expect(subject).to have_received(:put).with(
            '/blogs/1/comments/2?q1=foo&api_key=fooKey',
            {
              params: '{"text":"Some comment"}',
              headers: { 'CONTENT_TYPE' => 'application/json' }
            }
          )
        end
      end
    end
  end
end
