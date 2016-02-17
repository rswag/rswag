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
      context 'by default' do
        before { subject.run_test('/blogs', 'post', test) }

        it "submits request based on 'default' and 'example' param values" do
          expect(test).to have_received(:post).with(
            '/blogs',
            { 'title' => 'Test Blog', 'content' => 'Hello World' },
            { 'X-Forwarded-For' => 'client1' }
          )
        end

        it "asserts response matches first 2xx status in operation 'responses'" do
          expect(test).to have_received(:assert_response).with(200)
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
            { 'title' => 'foobar' },
            { 'X-Forwarded-For' => '192.168.1.1' }
          )
        end
      end

      context 'expected status explicitly params' do
        before do
          subject.run_test('/blogs', 'post', test) do
            expect 400
          end
        end

        it "asserts response matches params status" do
          expect(test).to have_received(:assert_response).with(400)
        end
      end
    end
  end
end
