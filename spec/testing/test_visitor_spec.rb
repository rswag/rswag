require 'rails_helper'
require 'swagger_rails/testing/test_visitor'

module SwaggerRails

  describe TestVisitor do
    subject { described_class.new(swagger) }
    let(:swagger) do
      file_path = File.join(Rails.root, 'config/swagger', 'v1/swagger.json')
      JSON.parse(File.read(file_path))
    end
    let(:test) { spy('test') }

    describe '#run_test' do
      before do
        allow(test).to receive(:response).and_return(OpenStruct.new(body: "{}"))
      end

      context 'by default' do
        before { subject.run_test('/blogs', 'post', test) }

        it "submits request based on 'default' and 'example' param values" do
          expect(test).to have_received(:post).with(
            '/blogs',
            { 'title' => 'Test Blog', 'content' => 'Hello World' }.to_json,
            { 'X-Forwarded-For' => 'client1', 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
          )
        end

        it "asserts response matches spec'd 2xx status" do
          expect(test).to have_received(:assert_response).with(201)
        end

        it "asserts response body matches schema 'example' for 2xx status" do
          expect(test).to have_received(:assert_equal).with(
            { 'title' => 'Test Blog', 'content' => 'Hello World' },
            {}
          )
        end
      end

      context 'param values explicitly provided' do
        before do
          subject.run_test('/blogs', 'post', test) do
            set blog: { 'title' => 'foobar' }
            set 'X-Forwarded-For' => '192.168.1.1'
          end
        end

        it 'submits a request based on provided param values' do
          expect(test).to have_received(:post).with(
            '/blogs',
            { 'title' => 'foobar' }.to_json,
            { 'X-Forwarded-For' => '192.168.1.1', 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
          )
        end
      end

      context 'expected status explicitly set' do
        before do
          subject.run_test('/blogs', 'post', test) do
            expect 400
          end
        end

        it "asserts response matches set status" do
          expect(test).to have_received(:assert_response).with(400)
        end

        it "asserts response body matches schema 'example' for set status" do
          expect(test).to have_received(:assert_equal).with(
            { 'title' => [ 'is required' ] },
            {}
          )
        end
      end
    end
  end
end
