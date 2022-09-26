# frozen_string_literal: true

require 'rswag/specs/example_helpers'

module Rswag
  module Specs
    RSpec.describe ExampleHelpers do
      subject { double('example') }

      before do
        subject.extend(ExampleHelpers)
        allow(Rswag::Specs).to receive(:config).and_return(config)
        allow(config).to receive(:get_swagger_doc).and_return(swagger_doc)
        stub_const('Rswag::Specs::RAILS_VERSION', 3)
      end
      let(:config) { double('config') }
      let(:swagger_doc) do
        {
          swagger: '2.0',
          securityDefinitions: {
            api_key: {
              type: :apiKey,
              name: 'api_key',
              in: :query
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
              { name: :blog_id, in: :path, type: 'integer' },
              { name: 'id', in: :path, type: 'integer' },
              { name: 'q1', in: :query, type: 'string' },
              { name: :blog, in: :body, schema: { type: 'object' } }
            ],
            security: [
              { api_key: [] }
            ]
          }
        }
      end

      describe '#submit_request(metadata)' do
        before do
          allow(subject).to receive(:blog_id).and_return(1)
          allow(subject).to receive(:id).and_return(2)
          allow(subject).to receive(:q1).and_return('foo')
          allow(subject).to receive(:api_key).and_return('fooKey')
          allow(subject).to receive(:blog).and_return(text: 'Some comment')
          allow(subject).to receive(:put)
          subject.submit_request(metadata)
        end

        it "submits a request built from metadata and 'let' values" do
          expect(subject).to have_received(:put).with(
            '/blogs/1/comments/2?q1=foo&api_key=fooKey',
            '{"text":"Some comment"}',
            { 'CONTENT_TYPE' => 'application/json' }
          )
        end
      end
    end
  end
end
