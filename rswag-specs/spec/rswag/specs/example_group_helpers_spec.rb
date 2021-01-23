# frozen_string_literal: true

require 'rswag/specs/example_group_helpers'

module Rswag
  module Specs
    RSpec.describe ExampleGroupHelpers do
      subject { double('example_group') }

      before do
        subject.extend ExampleGroupHelpers
        allow(subject).to receive(:describe)
        allow(subject).to receive(:context)
        allow(subject).to receive(:metadata).and_return(api_metadata)
      end
      let(:api_metadata) { {} }

      describe '#path(path)' do
        before { subject.path('/blogs') }

        it "delegates to 'describe' with 'path' metadata" do
          expect(subject).to have_received(:describe).with(
            '/blogs', path_item: { template: '/blogs' }
          )
        end
      end

      describe '#get|post|patch|put|delete|head|options|trace(verb, summary)' do
        before { subject.post('Creates a blog') }

        it "delegates to 'describe' with 'operation' metadata" do
          expect(subject).to have_received(:describe).with(
            :post, operation: { verb: :post, summary: 'Creates a blog' }
          )
        end
      end

      describe '#tags|description|operationId|consumes|produces|schemes|deprecated|security(value)' do
        before do
          subject.tags('Blogs', 'Admin')
          subject.description('Some description')
          subject.operationId('createBlog')
          subject.consumes('application/json', 'application/xml')
          subject.produces('application/json', 'application/xml')
          subject.schemes('http', 'https')
          subject.deprecated(true)
          subject.security(api_key: [])
        end
        let(:api_metadata) { { operation: {} } }

        it "adds to the 'operation' metadata" do
          expect(api_metadata[:operation]).to match(
            tags: ['Blogs', 'Admin'],
            description: 'Some description',
            operationId: 'createBlog',
            consumes: ['application/json', 'application/xml'],
            produces: ['application/json', 'application/xml'],
            schemes: ['http', 'https'],
            deprecated: true,
            security: { api_key: [] }
          )
        end
      end

      describe '#parameter(attributes)' do
        context "when called at the 'path' level" do
          before { subject.parameter(name: :blog, in: :body, schema: { type: 'object' }) }
          let(:api_metadata) { { path_item: {} } } # i.e. operation not defined yet

          it "adds to the 'path_item parameters' metadata" do
            expect(api_metadata[:path_item][:parameters]).to match(
              [name: :blog, in: :body, schema: { type: 'object' }]
            )
          end
        end

        context "when called at the 'operation' level" do
          before { subject.parameter(name: :blog, in: :body, schema: { type: 'object' }) }
          let(:api_metadata) { { path_item: {}, operation: {} } } # i.e. operation defined

          it "adds to the 'operation parameters' metadata" do
            expect(api_metadata[:operation][:parameters]).to match(
              [name: :blog, in: :body, schema: { type: 'object' }]
            )
          end
        end

        context "'path' parameter" do
          before { subject.parameter(name: :id, in: :path) }
          let(:api_metadata) { { operation: {} } }

          it "automatically sets the 'required' flag" do
            expect(api_metadata[:operation][:parameters]).to match(
              [name: :id, in: :path, required: true]
            )
          end
        end

        context "when 'in' parameter key is not defined" do
          before { subject.parameter(name: :id) }
          let(:api_metadata) { { operation: {} } }

          it "does not require the 'in' parameter key" do
            expect(api_metadata[:operation][:parameters]).to match([name: :id])
          end
        end
      end

      describe '#response(code, description)' do
        before { subject.response('201', 'success') }

        it "delegates to 'context' with 'response' metadata" do
          expect(subject).to have_received(:context).with(
            'success', response: { code: '201', description: 'success' }
          )
        end
      end

      describe '#schema(value)' do
        before { subject.schema(type: 'object') }
        let(:api_metadata) { { response: {} } }

        it "adds to the 'response' metadata" do
          expect(api_metadata[:response][:schema]).to match(type: 'object')
        end
      end

      describe '#header(name, attributes)' do
        before { subject.header('Date', type: 'string') }
        let(:api_metadata) { { response: {} } }

        it "adds to the 'response headers' metadata" do
          expect(api_metadata[:response][:headers]).to match(
            'Date' => { type: 'string' }
          )
        end
      end

      describe '#examples(example)' do
        let(:json_example) do
          {
            'application/json' => {
              foo: 'bar'
            }
          }
        end
        let(:api_metadata) { { response: {} } }

        before do
          subject.examples(json_example)
        end

        it "adds to the 'response examples' metadata" do
          expect(api_metadata[:response][:examples]).to eq(json_example)
        end
      end
    end
  end
end
