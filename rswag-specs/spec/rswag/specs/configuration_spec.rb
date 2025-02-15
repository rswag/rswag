# frozen_string_literal: true

require 'rswag/specs/configuration'
require 'climate_control'

RSpec.describe Rswag::Specs::Configuration do
  subject { described_class.new(rspec_config) }

  let(:rspec_config) do
    OpenStruct.new(
      openapi_root: 'foobar',
      openapi_specs: {
        'v1/openapi.json' => { openapi: '3.0.0', info: { title: 'v1' } },
        'v2/openapi.json' => { openapi: '3.0.1', info: { title: 'v2' } }
      },
      openapi_format: :yaml,
      rswag_dry_run: nil,
      openapi_all_properties_required: nil,
      openapi_no_additional_properties: nil
    )
  end

  describe '#openapi_root' do
    let(:response) { subject.openapi_root }

    context 'when provided in rspec config' do
      it { expect(response).to eq('foobar') }
    end

    context 'when not provided' do
      let(:rspec_config) { super().tap { |c| c.openapi_root = nil } }

      it { expect { response }.to raise_error Rswag::Specs::ConfigurationError }
    end
  end

  describe '#openapi_specs' do
    let(:response) { subject.openapi_specs }

    context 'when provided in rspec config' do
      it { expect(response).to be_an_instance_of(Hash) }
    end

    context 'when not provided' do
      let(:rspec_config) { super().tap { |c| c.openapi_specs = nil } }

      it { expect { response }.to raise_error Rswag::Specs::ConfigurationError }
    end

    context 'when provided but empty' do
      let(:rspec_config) { super().tap { |c| c.openapi_specs = {} } }

      it { expect { response }.to raise_error Rswag::Specs::ConfigurationError }
    end
  end

  describe '#openapi_format' do
    let(:response) { subject.openapi_format }

    context 'when provided in rspec config' do
      it { expect(response).to be_an_instance_of(Symbol) }
    end

    context 'when an unsupported format is provided' do
      let(:rspec_config) { super().tap { |c| c.openapi_format = :xml } }

      it { expect { response }.to raise_error Rswag::Specs::ConfigurationError }
    end

    context 'when not provided' do
      let(:rspec_config) { super().tap { |c| c.openapi_format = nil } }

      it { expect(response).to eq(:json) }
    end
  end

  describe '#rswag_dry_run' do
    let(:response) { subject.rswag_dry_run }

    context 'when not provided' do
      let(:rspec_config) { super().tap { |c| c.rswag_dry_run = nil } }

      it { expect(response).to be(true) }
    end

    context 'when the environment variable is set to 0' do
      it 'returns false' do
        ClimateControl.modify RSWAG_DRY_RUN: '0' do
          expect(response).to be(false)
        end
      end
    end

    context 'when the environment variable is set to 1' do
      it 'returns true' do
        ClimateControl.modify RSWAG_DRY_RUN: '1' do
          expect(response).to be(true)
        end
      end
    end

    context 'when provided in rspec config' do
      let(:rspec_config) { super().tap { |c| c.rswag_dry_run = false } }

      it { expect(response).to be(false) }
    end
  end

  describe '#get_openapi_spec(tag=nil)' do
    let(:openapi_spec) { subject.get_openapi_spec(tag) }

    context 'when no tag is provided' do
      let(:tag) { nil }

      it 'returns the first doc in rspec config' do
        expect(openapi_spec).to match hash_including(info: { title: 'v1' })
      end
    end

    context 'when the tag is provided with a matching doc' do
      let(:tag) { 'v2/openapi.json' }

      it 'returns the matching doc in rspec config' do
        expect(openapi_spec).to match hash_including(info: { title: 'v2' })
      end
    end

    context 'when the tag is provided with no matching doc' do
      let(:tag) { 'foobar' }

      it { expect { openapi_spec }.to raise_error Rswag::Specs::ConfigurationError }
    end
  end

  describe '#openapi_all_properties_required' do
    let(:response) { subject.openapi_all_properties_required }

    context 'when not provided' do
      let(:rspec_config) { super().tap { |c| c.openapi_all_properties_required = nil } }

      it { expect(response).to be(false) }
    end

    context 'when provided in rspec config' do
      let(:rspec_config) { super().tap { |c| c.openapi_all_properties_required = true } }

      it { expect(response).to be(true) }
    end
  end

  describe '#openapi_no_additional_properties' do
    let(:response) { subject.openapi_no_additional_properties }

    context 'when not provided' do
      let(:rspec_config) { super().tap { |c| c.openapi_no_additional_properties = nil } }

      it { expect(response).to be(false) }
    end

    context 'when provided in rspec config' do
      let(:rspec_config) { super().tap { |c| c.openapi_no_additional_properties = true } }

      it { expect(response).to be(true) }
    end
  end
end
