# frozen_string_literal: true

require 'rswag/specs/configuration'
require 'climate_control'

RSpec.describe Rswag::Specs::Configuration do
  subject { described_class.new(rspec_config) }

  let(:rspec_config) do
    OpenStruct.new(
      openapi_root: openapi_root, openapi_specs: openapi_specs,
      openapi_format: openapi_format, rswag_dry_run: rswag_dry_run,
      openapi_strict_schema_validation: openapi_strict_schema_validation,
      openapi_all_properties_required: openapi_all_properties_required,
      openapi_no_additional_properties: openapi_no_additional_properties
    )
  end
  let(:openapi_root) { 'foobar' }
  let(:openapi_specs) do
    {
      'v1/swagger.json' => { swagger: '2.0.0', info: { title: 'v1' } },
      'v2/swagger.json' => { openapi: '3.0.0', info: { title: 'v2' } }
    }
  end
  let(:openapi_format) { :yaml }
  let(:rswag_dry_run) { nil }
  let(:openapi_strict_schema_validation) { nil }
  let(:openapi_all_properties_required) { nil }
  let(:openapi_no_additional_properties) { nil }

  describe '#openapi_root' do
    let(:response) { subject.openapi_root }

    context 'provided in rspec config' do
      it { expect(response).to eq('foobar') }
    end

    context 'not provided' do
      let(:openapi_root) { nil }
      it { expect { response }.to raise_error Rswag::Specs::ConfigurationError }
    end
  end

  describe '#openapi_specs' do
    let(:response) { subject.openapi_specs }

    context 'provided in rspec config' do
      it { expect(response).to be_an_instance_of(Hash) }
    end

    context 'not provided' do
      let(:openapi_specs) { nil }
      it { expect { response }.to raise_error Rswag::Specs::ConfigurationError }
    end

    context 'provided but empty' do
      let(:openapi_specs) { {} }
      it { expect { response }.to raise_error Rswag::Specs::ConfigurationError }
    end
  end

  describe '#openapi_format' do
    let(:response) { subject.openapi_format }

    context 'provided in rspec config' do
      it { expect(response).to be_an_instance_of(Symbol) }
    end

    context 'unsupported format provided' do
      let(:openapi_format) { :xml }

      it { expect { response }.to raise_error Rswag::Specs::ConfigurationError }
    end

    context 'not provided' do
      let(:openapi_format) { nil }

      it { expect(response).to eq(:json) }
    end
  end

  describe '#rswag_dry_run' do
    let(:response) { subject.rswag_dry_run }

    context 'when not provided' do
      let(:rswag_dry_run) { nil }
      it { expect(response).to eq(true) }
    end

    context 'when environment variable is provided' do
      context 'when set to 0' do
        it 'returns false' do
          ClimateControl.modify RSWAG_DRY_RUN: '0' do
            expect(response).to eq(false)
          end
        end
      end

      context 'when set to 1' do
        it 'returns true' do
          ClimateControl.modify RSWAG_DRY_RUN: '1' do
            expect(response).to eq(true)
          end
        end
      end
    end

    context 'when deprecated environment variable is provided' do
      context 'when set to 0' do
        it 'returns false' do
          ClimateControl.modify SWAGGER_DRY_RUN: '0' do
            expect(response).to eq(false)
          end
        end
      end

      context 'when set to 1' do
        it 'returns true' do
          ClimateControl.modify SWAGGER_DRY_RUN: '1' do
            expect(response).to eq(true)
          end
        end
      end
    end

    context 'when provided in rspec config' do
      let(:rswag_dry_run) { false }
      it { expect(response).to eq(false) }
    end
  end

  describe '#get_openapi_spec(tag=nil)' do
    let(:openapi_spec) { subject.get_openapi_spec(tag) }

    context 'no tag provided' do
      let(:tag) { nil }

      it 'returns the first doc in rspec config' do
        expect(openapi_spec).to match hash_including(info: { title: 'v1' })
      end
    end

    context 'tag provided' do
      context 'matching doc' do
        let(:tag) { 'v2/swagger.json' }

        it 'returns the matching doc in rspec config' do
          expect(openapi_spec).to match hash_including(info: { title: 'v2' })
        end
      end

      context 'no matching doc' do
        let(:tag) { 'foobar' }
        it { expect { openapi_spec }.to raise_error Rswag::Specs::ConfigurationError }
      end
    end
  end

  describe '#get_openapi_spec_version' do
    let(:response) { subject.get_openapi_spec_version(tag) }

    context 'when tag provided' do
      context 'with matching doc' do
        let(:tag) { 'v2/swagger.json' }

        it 'returns the matching version in rspec config' do
          expect(response).to eq('3.0.0')
        end
      end

      context 'with no matching doc' do
        let(:tag) { 'foobar' }
        it { expect { response }.to raise_error Rswag::Specs::ConfigurationError }
      end
    end

    context 'when no tag provided' do
      let(:tag) { nil }

      it 'returns the first version in rspec config' do
        expect(response).to eq('2.0.0')
      end
    end
  end

  describe '#openapi_strict_schema_validation' do
    let(:response) { subject.openapi_strict_schema_validation }

    context 'when not provided' do
      let(:openapi_strict_schema_validation) { nil }
      it { expect(response).to eq(false) }
    end

    context 'when provided in rspec config' do
      let(:openapi_strict_schema_validation) { true }
      it { expect(response).to eq(true) }
    end
  end

  describe '#openapi_all_properties_required' do
    let(:response) { subject.openapi_all_properties_required }

    context 'when not provided' do
      let(:openapi_all_properties_required) { nil }
      it { expect(response).to eq(false) }
    end

    context 'when provided in rspec config' do
      let(:openapi_all_properties_required) { true }
      it { expect(response).to eq(true) }
    end
  end

  describe '#openapi_no_additional_properties' do
    let(:response) { subject.openapi_no_additional_properties }

    context 'when not provided' do
      let(:openapi_no_additional_properties) { nil }
      it { expect(response).to eq(false) }
    end

    context 'when provided in rspec config' do
      let(:openapi_no_additional_properties) { true }
      it { expect(response).to eq(true) }
    end
  end
end
