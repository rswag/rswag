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
  end

  describe '::config' do
    it 'returns a configuration object' do
      expect(described_class.config).to be_a Rswag::Specs::Configuration
    end
  end
end
