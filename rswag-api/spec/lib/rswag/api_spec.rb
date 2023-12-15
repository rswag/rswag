require 'spec_helper'

RSpec.describe Rswag::Api do
  describe '::configure' do
    it 'yields a configuration object' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(instance_of(Rswag::Api::Configuration))
    end
  end
end
