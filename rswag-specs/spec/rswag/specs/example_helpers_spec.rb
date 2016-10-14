require 'rswag/specs/example_helpers'

module Rswag
  module Specs

    describe ExampleHelpers do
      subject { double('example') }

      before do
        subject.extend ExampleHelpers
        # Mock out some infrastructure
        stub_const('Rails::VERSION::MAJOR', 3)
        config = double('config')
        allow(config).to receive(:get_swagger_doc).and_return(global_metadata)
        allow(subject).to receive(:config).and_return(config)
      end
      let(:api_metadata) do
        {
          path_item: { template: '/blogs/{blog_id}/comments/{id}' },
          operation: {
            verb: :put,
            summary: 'Updates a blog',
            parameters: [
              { name: :blog_id, in: :path, type: 'integer' },
              { name: 'id', in: :path, type: 'integer' },
              { name: 'q1', in: :query, type: 'string' },
              { name: :blog, in: :body, schema: { type: 'object' } }
            ],
            security: {
              api_key: []
            }
          }
        }
      end
      let(:global_metadata) do
        {
          securityDefinitions: {
            api_key: {
              type: :apiKey,
              name: 'api_key',
              in: :query
            }
          }
        }
      end

      describe '#submit_request(api_metadata)' do
        before do
          allow(subject).to receive(:blog_id).and_return(1)
          allow(subject).to receive(:id).and_return(2)
          allow(subject).to receive(:q1).and_return('foo')
          allow(subject).to receive(:api_key).and_return('fookey')
          allow(subject).to receive(:blog).and_return(text: 'Some comment')
          allow(subject).to receive(:put)
          subject.submit_request(api_metadata)
        end

        it "submits a request built from metadata and 'let' values" do
          expect(subject).to have_received(:put).with(
            '/blogs/1/comments/2?q1=foo&api_key=fookey',
            "{\"text\":\"Some comment\"}",
            {}
          )
        end
      end
    end
  end
end
