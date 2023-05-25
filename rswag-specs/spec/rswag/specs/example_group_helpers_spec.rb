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
        context 'when called without keyword arguments' do
          before { subject.post('Creates a blog') }

          it "delegates to 'describe' with 'operation' metadata" do
            expect(subject).to have_received(:describe).with(
              :post, operation: { verb: :post, summary: 'Creates a blog' }
            )
          end
        end

        context 'when called with keyword arguments' do
          before { subject.post('Creates a blog', foo: 'bar') }

          it "delegates to 'describe' with 'operation' metadata and provided metadata" do
            expect(subject).to have_received(:describe).with(
              :post, operation: { verb: :post, summary: 'Creates a blog' }, foo: 'bar'
            )
          end
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

      describe '#request_body_example(value:, summary: nil, name: nil)' do
        context "when adding one example" do
          before { subject.request_body_example(value: value)}
          let(:api_metadata) { { operation: {} } }
          let(:value) { { field: 'A', another_field: 'B' } }

          it "assigns the example to the metadata" do
            expect(api_metadata[:operation][:request_examples].length()).to eq(1)
            expect(api_metadata[:operation][:request_examples][0]).to eq({ value: value, name: 0 })
          end
        end

        context "when adding multiple examples with additional information" do
          before {
            subject.request_body_example(value: example_one)
            subject.request_body_example(value: example_two, name: example_two_name, summary: example_two_summary)
          }
          let(:api_metadata) { { operation: {} } }
          let(:example_one) { { field: 'A', another_field: 'B' } }
          let(:example_two) { { field: 'B', another_field: 'C' } }
          let(:example_two_name) { 'example_two' }
          let(:example_two_summary) { 'An example description' }

          it "assigns all examples to the metadata" do
            expect(api_metadata[:operation][:request_examples].length()).to eq(2)
            expect(api_metadata[:operation][:request_examples][0]).to eq({ value: example_one, name: 0 })
            expect(api_metadata[:operation][:request_examples][1]).to eq({ value: example_two, name: example_two_name, summary: example_two_summary })
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
          subject.examples(mime => json_example)
        end

        it "adds to the 'response examples' metadata" do
          expect(api_metadata[:response][:content]).to match(
            mime => {
              examples: {
                example_0: {
                  value: json_example
                }
              }
            }
          )
        end
      end

      describe '#example(single)' do
        let(:mime) { 'application/json' }
        let(:summary) { "this is a summary"}
        let(:description) { "this is an example description "}
        let(:json_example) do
          {
              foo: 'bar'
          }
        end
        let(:api_metadata) { { response: {} } }

        before do
          subject.example(mime, :example_key, json_example, summary, description)
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

      describe "#run_test!" do
        let(:rspec_version) { 3 }
        let(:api_metadata) {
          {
            response: {
              code: "200"
            }
          }
        }

        before do
          stub_const("RSPEC_VERSION", rspec_version)
          allow(subject).to receive(:before)
        end

        it "executes a specification" do
          expected_spec_description = "returns a 200 response"
          expect(subject).to receive(:it).with(expected_spec_description, rswag: true)
          subject.run_test!
        end

        context "when options[:description] is passed" do
          it "executes a specification described with passed description" do
            expected_spec_description = "returns a 200 response - with a custom description"
            expect(subject).to receive(:it).with(expected_spec_description, rswag: true)
            subject.run_test!(expected_spec_description)
          end
        end
      end
    end
  end
end
