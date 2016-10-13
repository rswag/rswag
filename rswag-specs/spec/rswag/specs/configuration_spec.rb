require 'rswag/specs/configuration'

module Rswag
  module Specs

    describe Configuration do
      subject { described_class.new(rspec_config) }

      let(:rspec_config) { OpenStruct.new(swagger_root: swagger_root, swagger_docs: swagger_docs) }
      let(:swagger_root) { 'foobar' }
      let(:swagger_docs) do
        {
          'v1/swagger.json' => { info: { title: 'v1' } },
          'v2/swagger.json' => { info: { title: 'v2' } }
        }
      end

      describe '#swagger_root' do
        let(:response) { subject.swagger_root }

        context 'provided in rspec config' do
          it { expect(response).to eq('foobar') }
        end

        context 'not provided' do
          let(:swagger_root) { nil }
          it { expect { response }.to raise_error ConfigurationError }
        end
      end

      describe '#swagger_docs' do
        let(:response) { subject.swagger_docs }

        context 'provided in rspec config' do
          it { expect(response).to be_an_instance_of(Hash) }
        end

        context 'not provided' do
          let(:swagger_docs) { nil }
          it { expect { response }.to raise_error ConfigurationError }
        end

        context 'provided but empty' do
          let(:swagger_docs) { {} }
          it { expect { response }.to raise_error ConfigurationError }
        end
      end

      describe '#get_swagger_doc(tag=nil)' do
        let(:swagger_doc) { subject.get_swagger_doc(tag) }

        context 'no tag provided' do
          let(:tag) { nil }

          it 'returns the first doc in rspec config' do
            expect(swagger_doc).to eq(info: { title: 'v1' })
          end
        end

        context 'tag provided' do
          context 'matching doc' do
            let(:tag) { 'v2/swagger.json' }

            it 'returns the matching doc in rspec config' do
              expect(swagger_doc).to eq(info: { title: 'v2' })
            end
          end

          context 'no matching doc' do
            let(:tag) { 'foobar' }
            it { expect { swagger_doc }.to raise_error ConfigurationError }
          end
        end
      end
    end
  end
end
