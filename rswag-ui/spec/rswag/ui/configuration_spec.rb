require 'rswag/ui/configuration'

require_relative '../../spec_helper'

RSpec.describe Rswag::Ui::Configuration do
  describe '#swagger_endpoints'

  describe '#basic_auth_enabled' do
    context 'when unspecified' do
      it 'defaults to false' do
        configuration = described_class.new
        basic_auth_enabled = configuration.basic_auth_enabled

        expect(basic_auth_enabled).to be(false)
      end
    end

    context 'when specified' do
      context 'when set to true' do
        it 'returns true' do
          configuration = described_class.new
          configuration.basic_auth_enabled = true
          basic_auth_enabled = configuration.basic_auth_enabled

          expect(basic_auth_enabled).to be(true)
        end
      end

      context 'when set to false' do
        it 'returns false' do
          configuration = described_class.new
          configuration.basic_auth_enabled = false
          basic_auth_enabled = configuration.basic_auth_enabled

          expect(basic_auth_enabled).to be(false)
        end
      end
    end
  end

  describe '#basic_auth_credentials' do
    it 'sets the username and password' do
      configuration = described_class.new
      configuration.basic_auth_credentials 'foo', 'bar'
      credentials = configuration.config_object[:basic_auth]

      expect(credentials).to eq(username: 'foo', password: 'bar')
    end
  end

  describe '#get_binding'
end
