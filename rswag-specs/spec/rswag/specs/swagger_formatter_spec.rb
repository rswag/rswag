require 'rswag/specs/swagger_formatter'
require 'ostruct'

module Rswag
  module Specs

    RSpec.describe SwaggerFormatter do
      subject { described_class.new(output, config) }

      # Mock out some infrastructure
      before do
        allow(config).to receive(:swagger_root).and_return(swagger_root)
      end
      let(:config) { double('config') }
      let(:output) { double('output').as_null_object }
      let(:swagger_root) { File.expand_path('../tmp/swagger', __FILE__) }

      describe '#example_group_finished(notification)' do
        before do
          allow(config).to receive(:get_swagger_doc).and_return(swagger_doc)
          subject.example_group_finished(notification)
        end
        let(:swagger_doc) { {} }
        let(:notification) { OpenStruct.new(group: OpenStruct.new(metadata: api_metadata)) }
        let(:api_metadata) do
          {
            path_item: { template: '/blogs' },
            operation: { verb: :post, summary: 'Creates a blog' },
            response: { code: '201', description: 'blog created' }
          }
        end

        it 'converts to swagger and merges into the corresponding swagger doc' do
          expect(swagger_doc).to match(
            paths: {
              '/blogs' => {
                post: {
                  summary: 'Creates a blog',
                  responses: {
                    '201' => { description: 'blog created' }
                  }
                }
              }
            }
          )
        end
      end

      describe '#stop' do
        before do
          FileUtils.rm_r(swagger_root) if File.exists?(swagger_root)
          allow(config).to receive(:swagger_docs).and_return(
            'v1/swagger.json' => { info: { version: 'v1' } },
            'v2/swagger.json' => { info: { version: 'v2' } }
          )
          allow(config).to receive(:swagger_format).and_return(swagger_format)
          subject.stop(notification)
        end

        let(:notification) { double('notification') }
        context 'with default format' do
          let(:swagger_format) { :json }

          it 'writes the swagger_doc(s) to file' do
            expect(File).to exist("#{swagger_root}/v1/swagger.json")
            expect(File).to exist("#{swagger_root}/v2/swagger.json")
            expect { JSON.parse(File.read("#{swagger_root}/v2/swagger.json")) }.not_to raise_error
          end
        end

        context 'with yaml format' do
          let(:swagger_format) { :yaml }

          it 'writes the swagger_doc(s) as yaml' do
            expect(File).to exist("#{swagger_root}/v1/swagger.json")
            expect { JSON.parse(File.read("#{swagger_root}/v1/swagger.json")) }.to raise_error(JSON::ParserError)
            # Psych::DisallowedClass would be raised if we do not pre-process ruby symbols
            expect { YAML.safe_load(File.read("#{swagger_root}/v1/swagger.json")) }.not_to raise_error
          end
        end

        after do
          FileUtils.rm_r(swagger_root) if File.exists?(swagger_root)
        end
      end
    end
  end
end
