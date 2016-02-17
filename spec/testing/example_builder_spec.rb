require 'rails_helper'
require 'swagger_rails/testing/example_builder'

module SwaggerRails

  describe ExampleBuilder do
    subject { described_class.new(path, method, swagger) }
    let(:swagger) do
      file_path = File.join(Rails.root, 'config/swagger', 'v1/swagger.json')
      JSON.parse(File.read(file_path))
    end

    describe '#path' do
      context 'operation with path params' do
        let(:path) { '/blogs/{id}' }
        let(:method) { 'get' }

        context 'by default' do
          it "returns path based on 'default' values" do
            expect(subject.path).to eq('/blogs/123')
          end
        end

        context 'values explicitly set' do
          before { subject.set id: '456' }
          it 'returns path based on set values' do
            expect(subject.path).to eq('/blogs/456')
          end
        end
      end

      context 'swagger includes basePath' do
        before { swagger['basePath'] = '/foobar' }
        let(:path) { '/blogs' }
        let(:method) { 'post' }

        it 'returns path prefixed with basePath' do
          expect(subject.path).to eq('/foobar/blogs')
        end
      end
    end

    describe '#params' do
      context 'operation with body param' do
        let(:path) { '/blogs' }
        let(:method) { 'post' }

        context 'by default' do
          it "returns schema 'example'" do
            expect(subject.params).to eq(swagger['definitions']['Blog']['example'])
          end
        end

        context 'value explicitly set' do
          before { subject.set blog: { 'title' => 'foobar' } }
          it 'returns params value' do
            expect(subject.params).to eq({ 'title' => 'foobar' })
          end
        end
      end

      context 'operation with query params' do
        let(:path) { '/blogs' }
        let(:method) { 'get' }

        context 'by default' do
          it "returns query params based on 'default' values" do
            expect(subject.params).to eq({ 'published' => 'true', 'keywords' => 'Ruby on Rails' })
          end
        end

        context 'values explicitly set' do
          before { subject.set keywords: 'Java' }
          it 'returns query params based on set values' do
            expect(subject.params).to eq({ 'published' => 'true', 'keywords' => 'Java' })
          end
        end
      end
    end

    describe '#headers' do
      context 'operation with header params' do
        let(:path) { '/blogs' }
        let(:method) { 'post' }

        context 'by default' do
          it "returns headers based on 'default' values" do
            expect(subject.headers).to eq({ 'X-Forwarded-For' => 'client1' })
          end
        end

        context 'values explicitly params' do
          before { subject.set 'X-Forwarded-For' => '192.168.1.1' }
          it 'returns headers based on params values' do
            expect(subject.headers).to eq({ 'X-Forwarded-For' => '192.168.1.1' })
          end
        end
      end
    end

    describe '#expected_status' do
      let(:path) { '/blogs' }
      let(:method) { 'post' }

      context 'by default' do
        it "returns first 2xx status in 'responses'" do
          expect(subject.expected_status).to eq(200)
        end
      end

      context 'expected status explicitly params' do
        before { subject.expect 400 }
        it "returns params status" do
          expect(subject.expected_status).to eq(400)
        end
      end
    end
  end
end
