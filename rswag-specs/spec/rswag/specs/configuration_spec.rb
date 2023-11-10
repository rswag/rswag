# frozen_string_literal: true

require 'rswag/specs/configuration'

module Rswag
  module Specs
    RSpec.describe Configuration do
      subject { described_class.new(rspec_config) }

      let(:rspec_config) do
        OpenStruct.new(openapi_root: openapi_root, openapi_specs: openapi_specs, openapi_format: openapi_format)
      end
      let(:openapi_root) { 'foobar' }
      let(:openapi_specs) do
        {
          'v1/openapi.json' => { info: { title: 'v1' } },
          'v2/openapi.json' => { info: { title: 'v2' } }
        }
      end
      let(:openapi_format) { :yaml }

      describe '#openapi_root' do
        let(:response) { subject.openapi_root }

        context 'provided in rspec config' do
          it { expect(response).to eq('foobar') }
        end

        context 'not provided' do
          let(:openapi_root) { nil }
          it { expect { response }.to raise_error ConfigurationError }
        end
      end

      describe '#openapi_specs' do
        let(:response) { subject.openapi_specs }

        context 'provided in rspec config' do
          it { expect(response).to be_an_instance_of(Hash) }
        end

        context 'not provided' do
          let(:openapi_specs) { nil }
          it { expect { response }.to raise_error ConfigurationError }
        end

        context 'provided but empty' do
          let(:openapi_specs) { {} }
          it { expect { response }.to raise_error ConfigurationError }
        end
      end

      describe '#openapi_format' do
        let(:response) { subject.openapi_format }

        context 'provided in rspec config' do
          it { expect(response).to be_an_instance_of(Symbol) }
        end

        context 'unsupported format provided' do
          let(:openapi_format) { :xml }

          it { expect { response }.to raise_error ConfigurationError }
        end

        context 'not provided' do
          let(:openapi_format) { nil }

          it { expect(response).to eq(:json) }
        end
      end

      describe '#get_openapi_spec(tag=nil)' do
        let(:openapi_spec) { subject.get_openapi_spec(tag) }

        context 'no tag provided' do
          let(:tag) { nil }

          it 'returns the first doc in rspec config' do
            expect(openapi_spec).to eq(info: { title: 'v1' })
          end
        end

        context 'tag provided' do
          context 'matching doc' do
            let(:tag) { 'v2/openapi.json' }

            it 'returns the matching doc in rspec config' do
              expect(openapi_spec).to eq(info: { title: 'v2' })
            end
          end

          context 'no matching doc' do
            let(:tag) { 'foobar' }
            it { expect { openapi_spec }.to raise_error ConfigurationError }
          end
        end
      end
    end
  end
end
