# frozen_string_literal: true

RSpec.describe Rswag::Specs do
  describe 'settings' do
    let(:rspec_config) do
      RSpec::Core::Configuration.new.tap do |c|
        c.add_setting :openapi_root
      end
    end

    it 'defines openapi settings' do
      expect { rspec_config.openapi_root = 'foobar' }.not_to raise_error
    end

    it 'defines deprecated swagger settings' do
      allow(Rswag::Specs.deprecator).to receive(:warn)
      rspec_config.swagger_root = 'foobar'
      expect(rspec_config.openapi_root).to eq('foobar')
      expect(Rswag::Specs.deprecator).to(
        have_received(:warn)
          .with('swagger_root= is deprecated and will be removed from rswag-specs 3.0 (use openapi_root= instead)',
                any_args)
      )
    end
  end

  describe '::config' do
    it 'returns a configuration object' do
      expect(described_class.config).to be_a Rswag::Specs::Configuration
    end
  end
end
