require 'rails_helper'
require 'swagger_rails/testing/test_data_builder'

module SwaggerRails

  describe TestDataBuilder do
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

      context 'operation has body params' do
        let(:path) { '/blogs' }
        let(:method) { 'post' }

        context 'by default' do
          it "includes params built from 'default' values" do
            expect(test_data[:params]).to eq({ 'title' => 'Test Blog', 'content' => 'Hello World' })
          end
        end

        context 'values explicitly set' do
          before { subject.set blog: { 'title' => 'foobar' } }
          it 'includes params build from set values' do
            expect(test_data[:params]).to eq({ 'title' => 'foobar' })
          end
        end
      end

      context 'operation has header params' do
        let(:path) { '/blogs' }
        let(:method) { 'post' }

        context 'by default' do
          it "includes headers built from 'default' values" do
            expect(test_data[:headers]).to eq({ 'X-Forwarded-For' => 'client1' })
          end
        end

        context 'values explicitly params' do
          before { subject.set 'X-Forwarded-For' => '192.168.1.1' }
          it 'includes headers built from set values' do
            expect(test_data[:headers]).to eq({ 'X-Forwarded-For' => '192.168.1.1' })
          end
        end
      end
    end
  end
end
