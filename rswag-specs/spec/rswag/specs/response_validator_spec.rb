require 'rswag/specs/response_validator'

module Rswag
  module Specs

    describe ResponseValidator do
      subject { ResponseValidator.new(api_metadata, global_metadata) }

      let(:api_metadata) { { response: { code: 200 } } }
      let(:global_metadata) { {} }

      describe '#validate!(response)' do
        let(:call) { subject.validate!(response) }

        context "no 'schema' provided" do
          context 'response code matches' do
            let(:response) { OpenStruct.new(code: 200, body: '') }
            it { expect { call }.to_not raise_error }
          end

          context 'response code does not match' do
            let(:response) { OpenStruct.new(code: 201, body: '') }
            it { expect { call }.to raise_error UnexpectedResponse }
          end
        end

        context "'schema' provided" do
          before do
            api_metadata[:response][:schema] = {
              type: 'object',
              properties: { text: { type: 'string' } },
              required: [ 'text' ]
            }
          end

          context 'response code & body matches' do
            let(:response) { OpenStruct.new(code: 200, body: "{\"text\":\"Some comment\"}") }
            it { expect { call }.to_not raise_error }
          end

          context 'response code matches & body does not' do
            let(:response) { OpenStruct.new(code: 200, body: "{\"foo\":\"Some comment\"}") }
            it { expect { call }.to raise_error UnexpectedResponse }
          end
        end

        context "referenced 'schema' provided" do
          before do
            api_metadata[:response][:schema] = { '$ref' => '#/definitions/author' }
            global_metadata[:definitions] = {
              author: {
                type: 'object',
                properties: { name: { type: 'string' } },
                required: [ 'name' ]
              }
            }
          end

          context 'response code & body matches' do
            let(:response) { OpenStruct.new(code: 200, body: "{\"name\":\"Some name\"}") }
            it { expect { call }.to_not raise_error }
          end

          context 'response code matches & body does not' do
            let(:response) { OpenStruct.new(code: 200, body: "{\"foo\":\"Some name\"}") }
            it { expect { call }.to raise_error UnexpectedResponse }
          end
        end
      end
    end
  end
end
