require 'rswag/specs/swagger_formatter'
require 'ostruct'

module Rswag
  module Specs
    
    describe SwaggerFormatter do
      # Mock infrastructure - output, RSpec.configuration etc. 
      let(:output) { double('output').as_null_object }
      let(:swagger_root) { File.expand_path('../tmp', __FILE__) }
      let(:swagger_docs) do
        {
          'v1/swagger.json' => { info: { version: 'v1' } }
        }
      end
      let(:config) { OpenStruct.new(swagger_root: swagger_root, swagger_docs: swagger_docs) }
      before { allow(RSpec).to receive(:configuration).and_return(config) }

      subject { described_class.new(output) }

      describe '::new(output)' do
        context 'swagger_root not configured' do
          let(:swagger_root) { nil }
          it { expect { subject }.to raise_error ConfigurationError }
        end

        context 'swagger_docs not configured' do
          let(:swagger_docs) { nil }
          it { expect { subject }.to raise_error ConfigurationError }
        end
      end

      describe '#example_group_finished(notification)' do
        # Mock notification parameter
        let(:api_metadata) do
          {
            path: '/blogs',
            operation: { verb: :post, summary: 'Creates a blog' },
            response: { code: '201', description: 'blog created' }
          }
        end
        let(:notification) { OpenStruct.new(group: OpenStruct.new(metadata: api_metadata)) }

        let(:call) { subject.example_group_finished(notification) } 

        context 'single swagger_doc' do
          before { call }

          it 'converts metadata to swagger and merges into the doc' do
            expect(swagger_docs.values.first).to match(
              info: { version: 'v1' },
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

        context 'multiple swagger_docs' do
          let(:swagger_docs) do
            {
              'v1/swagger.json' => {},
              'v2/swagger.json' => {}
            }
          end

          context "no 'swagger_doc' tag" do
            before { call }

            it 'merges into the first doc' do
              expect(swagger_docs.values.first).to have_key(:paths)
            end
          end

          context "matching 'swagger_doc' tag" do
            before do
              api_metadata[:swagger_doc] = 'v2/swagger.json'
              call
            end

            it 'merges into the matched doc' do
              expect(swagger_docs.values.last).to have_key(:paths)
            end
          end

          context "non matching 'swagger_doc' tag" do
            before { api_metadata[:swagger_doc] = 'foobar' }
            it { expect { call }.to raise_error ConfigurationError }
          end
        end
      end

      describe '#stop' do
        let(:notification) { double('notification') }
        let(:swagger_docs) do
          {
            'v1/swagger.json' => { info: { version: 'v1' } }, 
            'v2/swagger.json' => { info: { version: 'v2' } }, 
          }
        end

        before do 
          FileUtils.rm_r(swagger_root) if File.exists?(swagger_root)
          subject.stop(notification)
        end

        it 'writes the swagger_doc(s) to file' do
          expect(File).to exist("#{swagger_root}/v1/swagger.json")
          expect(File).to exist("#{swagger_root}/v2/swagger.json")
        end

        after do
          FileUtils.rm_r(swagger_root) if File.exists?(swagger_root)
        end
      end
    end
  end
end
