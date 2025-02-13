# frozen_string_literal: true

require 'action_dispatch'

RSpec.describe Rswag::RouteParser do
  describe '#routes' do
    subject(:described_instance) { described_class.new(controller) }

    let(:controller) { 'api/v1/posts' }

    let(:routes) do
      [
        instance_double(
          ActionDispatch::Journey::Route,
          defaults: {
            controller: controller
          },
          path: instance_double(
            ActionDispatch::Journey::Path::Pattern,
            spec: instance_double(
              ActionDispatch::Journey::Parser,
              to_s: '/api/v1/posts/:id(.:format)'
            )
          ),
          verb: 'GET',
          requirements: {
            action: 'show',
            controller: controller
          },
          segments: %w[id format]
        )
      ]
    end

    let(:expectation) do
      {
        '/api/v1/posts/{id}' => {
          params: ['id'],
          actions: {
            'get' => {
              summary: 'show post'
            }
          }
        }
      }
    end

    before do
      allow(::Rails).to receive_message_chain('application.routes.routes') { routes }
    end

    it 'returns correct routes' do
      expect(described_instance.routes).to eq(expectation)
    end
  end
end
