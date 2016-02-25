require 'rails_helper'
require 'swagger_rails/testing/test_case_builder'

module SwaggerRails

  describe TestCaseBuilder do
    subject { described_class.new(path, method, swagger) }
    let(:swagger) do
      file_path = File.join(Rails.root, 'config/swagger', 'v1/swagger.json')
      JSON.parse(File.read(file_path))
    end

    describe '#test_data' do
      let(:test_data) { subject.test_data }

      context 'swagger includes basePath' do
        before { swagger['basePath'] = '/foobar' }
        let(:path) { '/blogs' }
        let(:method) { 'post' }

        it 'includes a path prefixed with basePath' do
          expect(test_data[:path]).to eq('/foobar/blogs')
        end
      end

      context 'operation has path params' do
        let(:path) { '/blogs/{id}' }
        let(:method) { 'get' }

        context 'by default' do
          it "includes a path built from 'default' values" do
            expect(test_data[:path]).to eq('/blogs/123')
          end
        end

        context 'values explicitly set' do
          before { subject.set id: '456' }
          it 'includes a path built from set values' do
            expect(test_data[:path]).to eq('/blogs/456')
          end
        end
      end

      context 'operation has query params' do
        let(:path) { '/blogs' }
        let(:method) { 'get' }

        context 'by default' do
          it "includes params built from 'default' values" do
            expect(test_data[:params]).to eq({ 'published' => 'true', 'keywords' => 'Ruby on Rails' })
          end
        end

        context 'values explicitly set' do
          before { subject.set keywords: 'Java' }
          it 'includes params build from set values' do
            expect(test_data[:params]).to eq({ 'published' => 'true', 'keywords' => 'Java' })
          end
        end
      end

      context 'operation has body param' do
        let(:path) { '/blogs' }
        let(:method) { 'post' }

        context 'by default' do
          it "includes params string based on schema 'example'" do
            expect(test_data[:params]).to eq({ 'title' => 'Test Blog', 'content' => 'Hello World' }.to_json)
          end
        end

        context 'values explicitly set' do
          before { subject.set blog: { 'title' => 'foobar' } }
          it 'includes params string based on set value' do
            expect(test_data[:params]).to eq({ 'title' => 'foobar' }.to_json)
          end
        end
      end

      context 'operation has header params' do
        let(:path) { '/blogs' }
        let(:method) { 'post' }

        context 'by default' do
          it "includes headers built from 'default' values" do
            expect(test_data[:headers]).to eq({
              'X-Forwarded-For' => 'client1',
              'CONTENT_TYPE' => 'application/json',
              'ACCEPT' => 'application/json'
            })
          end
        end

        context 'values explicitly params' do
          before { subject.set 'X-Forwarded-For' => '192.168.1.1' }
          it 'includes headers built from set values' do
            expect(test_data[:headers]).to eq({
              'X-Forwarded-For' => '192.168.1.1',
              'CONTENT_TYPE' => 'application/json',
              'ACCEPT' => 'application/json'
            })
          end
        end
      end

      context 'operation returns an object' do
        let(:path) { '/blogs' }
        let(:method) { 'post' }

        context 'by default' do
          it "includes expected_response based on spec'd 2xx status" do
            expect(test_data[:expected_response][:status]).to eq(201)
            expect(test_data[:expected_response][:body]).to eq({ 'title' => 'Test Blog', 'content' => 'Hello World' })
          end
        end

        context 'expected status explicitly set' do
          before { subject.expect 400 }
          it "includes expected_response based on set status" do
            expect(test_data[:expected_response][:status]).to eq(400)
            expect(test_data[:expected_response][:body]).to eq({ 'title' =>  [ 'is required' ] })
          end
        end
      end

      context 'operation returns an array' do
        let(:path) { '/blogs' }
        let(:method) { 'get' }

        context 'by default' do
          it "includes expected_response based on spec'd 2xx status" do
            expect(test_data[:expected_response][:status]).to eq(200)
            expect(test_data[:expected_response][:body]).to eq([ { 'title' => 'Test Blog', 'content' => 'Hello World' } ])
          end
        end
      end
    end
  end
end
