# frozen_string_literal: true

require 'rswag/specs/example_group_helpers'

module Rswag
  module Specs
    RSpec.describe ExampleGroupHelpers do
      subject(:mock_example_group) { Struct.new(:foo).new }

      before do
        mock_example_group.extend described_class
        allow(mock_example_group).to receive(:describe)
        allow(mock_example_group).to receive(:context)
        allow(mock_example_group).to receive(:metadata).and_return(api_metadata)
      end

      let(:api_metadata) { {} }

      describe '#path(path)' do
        before { mock_example_group.path('/blogs') }

        it "delegates to 'describe' with 'path' metadata" do
          expect(mock_example_group).to have_received(:describe).with(
            '/blogs', path_item: { template: '/blogs' }
          )
        end
      end

      describe '#get|post|patch|put|delete|head|options|trace(verb, summary)' do
        context 'when called without keyword arguments' do
          before { mock_example_group.post('Creates a blog') }

          it "delegates to 'describe' with 'operation' metadata" do
            expect(mock_example_group).to have_received(:describe).with(
              :post, operation: { verb: :post, summary: 'Creates a blog' }
            )
          end
        end

        context 'when called with keyword arguments' do
          before { mock_example_group.post('Creates a blog', foo: 'bar') }

          it "delegates to 'describe' with 'operation' metadata and provided metadata" do
            expect(mock_example_group).to have_received(:describe).with(
              :post, operation: { verb: :post, summary: 'Creates a blog' }, foo: 'bar'
            )
          end
        end
      end

      describe '#tags|description|operationId|consumes|produces|schemes|deprecated|security(value)' do
        before do
          mock_example_group.tags('Blogs', 'Admin')
          mock_example_group.description('Some description')
          mock_example_group.operationId('createBlog')
          mock_example_group.consumes('application/json', 'application/xml')
          mock_example_group.produces('application/json', 'application/xml')
          mock_example_group.schemes('http', 'https')
          mock_example_group.deprecated(true)
          mock_example_group.security(api_key: [])
        end

        let(:api_metadata) { { operation: {} } }

        it "adds to the 'operation' metadata" do
          expect(api_metadata[:operation]).to match(
            tags: %w[Blogs Admin],
            description: 'Some description',
            operationId: 'createBlog',
            consumes: ['application/json', 'application/xml'],
            produces: ['application/json', 'application/xml'],
            schemes: %w[http https],
            deprecated: true,
            security: { api_key: [] }
          )
        end
      end

      describe '#parameter(attributes)' do
        context "when called at the 'path' level" do
          before { mock_example_group.parameter(name: :blog, in: :body, schema: { type: 'object' }) }
          let(:api_metadata) { { path_item: {} } } # i.e. operation not defined yet

          it "adds to the 'path_item parameters' metadata" do
            expect(api_metadata[:path_item][:parameters]).to match(
              [name: :blog, in: :body, schema: { type: 'object' }]
            )
          end
        end

        context "when called at the 'operation' level" do
          before { mock_example_group.parameter(name: :blog, in: :body, schema: { type: 'object' }) }
          let(:api_metadata) { { path_item: {}, operation: {} } } # i.e. operation defined

          it "adds to the 'operation parameters' metadata" do
            expect(api_metadata[:operation][:parameters]).to match(
              [name: :blog, in: :body, schema: { type: 'object' }]
            )
          end
        end

        context "when defined as a 'path' parameter" do
          before { mock_example_group.parameter(name: :id, in: :path) }

          let(:api_metadata) { { operation: {} } }

          it "automatically sets the 'required' flag" do
            expect(api_metadata[:operation][:parameters]).to match(
              [name: :id, in: :path, required: true]
            )
          end
        end

        context "when 'in' parameter key is not defined" do
          before { mock_example_group.parameter(name: :id) }

          let(:api_metadata) { { operation: {} } }

          it "does not require the 'in' parameter key" do
            expect(api_metadata[:operation][:parameters]).to match([name: :id])
          end
        end
      end

      describe '#response(code, description)' do
        before { mock_example_group.response('201', 'success') }

        it "delegates to 'context' with 'response' metadata" do
          expect(mock_example_group).to have_received(:context).with(
            'success', response: { code: '201', description: 'success' }
          )
        end
      end

      describe '#schema(value)' do
        before { mock_example_group.schema(type: 'object') }

        let(:api_metadata) { { response: {} } }

        it "adds to the 'response' metadata" do
          expect(api_metadata[:response][:schema]).to match(type: 'object')
        end
      end

      describe '#header(name, attributes)' do
        before { mock_example_group.header('Date', type: 'string') }

        let(:api_metadata) { { response: {} } }

        it "adds to the 'response headers' metadata" do
          expect(api_metadata[:response][:headers]).to match(
            'Date' => { type: 'string' }
          )
        end
      end

      describe '#request_body_example(value:, summary: nil, name: nil)' do
        context 'when adding one example' do
          before { mock_example_group.request_body_example(value: value) }

          let(:api_metadata) { { operation: {} } }
          let(:value) { { field: 'A', another_field: 'B' } }

          it 'assigns the example to the metadata' do
            expect(api_metadata[:operation][:request_examples]).to eq([{ value: value, name: 0 }])
          end
        end

        context 'when adding multiple examples with additional information' do
          before do
            mock_example_group.request_body_example(value: example_one)
            mock_example_group.request_body_example(value: example_two,
                                                    name: example_two_name,
                                                    summary: example_two_summary)
          end

          let(:api_metadata) { { operation: {} } }
          let(:example_one) { { field: 'A', another_field: 'B' } }
          let(:example_two) { { field: 'B', another_field: 'C' } }
          let(:example_two_name) { 'example_two' }
          let(:example_two_summary) { 'An example description' }

          it 'assigns all examples to the metadata' do
            expect(api_metadata[:operation][:request_examples]).to have_attributes(
              length: 2,
              first: { value: example_one, name: 0 },
              second: { value: example_two, name: example_two_name, summary: example_two_summary }
            )
          end
        end
      end

      describe '#examples(example)' do
        let(:mime) { 'application/json' }
        let(:json_example) do
          {
            foo: 'bar'
          }
        end
        let(:api_metadata) { { response: {} } }

        before do
          mock_example_group.examples(mime => json_example)
        end

        it "adds to the 'response examples' metadata" do
          expect(api_metadata[:response][:content]).to match(
            mime => {
              examples: {
                example_0: { # rubocop:disable Naming/VariableNumber
                  value: json_example
                }
              }
            }
          )
        end
      end

      describe '#example(single)' do
        let(:mime) { 'application/json' }
        let(:summary) { 'this is a summary' }
        let(:description) { 'this is an example description ' }
        let(:json_example) do
          {
            foo: 'bar'
          }
        end
        let(:api_metadata) { { response: {} } }

        before do
          mock_example_group.example(mime, :example_key, json_example, summary, description)
        end

        it "adds to the 'response examples' metadata" do
          expect(api_metadata[:response][:content]).to match(
            mime => {
              examples: {
                example_key: {
                  value: json_example,
                  description: description,
                  summary: summary
                }
              }
            }
          )
        end
      end

      describe '#run_test!' do
        let(:api_metadata) do
          {
            response: {
              code: '200'
            }
          }
        end

        before do
          allow(mock_example_group).to receive(:before)
          allow(mock_example_group).to receive(:it)
        end

        it 'executes a specification' do
          expected_spec_description = 'returns a 200 response'
          mock_example_group.run_test!
          expect(mock_example_group).to have_received(:it).with(expected_spec_description, rswag: true)
        end

        context 'when options[:description] is passed' do
          it 'executes a specification described with passed description' do
            expected_spec_description = 'returns a 200 response - with a custom description'
            mock_example_group.run_test!(expected_spec_description)
            expect(mock_example_group).to have_received(:it).with(expected_spec_description, rswag: true)
          end
        end
      end
    end
  end
end
