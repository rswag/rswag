# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rswag::Api::Configuration do
  subject(:configuration) { described_class.new }

  describe '#swagger_root=' do
    it 'is deprecated' do
      allow(Rswag::Api.deprecator).to receive(:warn)
      configuration.swagger_root = 'foobar'
      expect(subject.openapi_root).to eq('foobar')
      expect(Rswag::Api.deprecator).to(
        have_received(:warn)
          .with('swagger_root= is deprecated and will be removed from rswag-api 3.0 (use openapi_root= instead)',
                any_args)
      )
    end
  end
end
