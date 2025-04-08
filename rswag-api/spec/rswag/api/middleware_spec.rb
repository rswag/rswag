# frozen_string_literal: true

require 'spec_helper'

require 'rails/application'
require 'rswag/api/middleware'
require 'rswag/api/configuration'

describe Rswag::Api::Middleware do
  let(:app) { instance_double(Rails::Application) }
  let(:config) do
    Rswag::Api::Configuration.new.tap { |c| c.openapi_root = File.expand_path('fixtures/openapi', __dir__) }
  end

  describe '#call(env)' do
    subject(:response) { described_class.new(app, config).call(env) }

    let(:env) do
      {
        'HTTP_HOST' => 'tempuri.org',
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => 'v1/openapi.json'
      }
    end

    context 'when given a path that maps to an existing openapi file' do
      it 'returns contents of the openapi file', :aggregate_failures do
        expect(response).to have_attributes(length: 3, first: '200')
        expect(response[1]).to include('Content-Type' => 'application/json')
        expect(response[2].join).to include('"title":"API V1"')
      end
    end

    context 'when configured with a Pathname similar to `Rails.root.join("openapi")`' do
      before { config.openapi_root = Pathname.new(config.openapi_root) }

      it 'returns a 200 status', :aggregate_failures do
        expect(response.length).to be(3)
        expect(response.first).to eql('200')
      end
    end

    context 'when openapi_headers are configured in the env with a different content type header' do
      before do
        config.openapi_headers = { 'Content-Type' => 'application/json; charset=UTF-8' }
      end

      it 'returns a 200 status with the header applied to the response', :aggregate_failures do
        expect(response.length).to be(3)
        expect(response.first).to eql('200')
        expect(response[1]).to include('Content-Type' => 'application/json; charset=UTF-8')
      end
    end

    context 'when openapi_headers are configured in the env with an additional header' do
      before do
        config.openapi_headers = { 'Access-Control-Allow-Origin' => '*' }
      end

      it 'applies the new header while retaining the other original headers', :aggregate_failures do
        expect(response.length).to be(3)
        expect(response.first).to eql('200')
        expect(response[1]).to include('Access-Control-Allow-Origin' => '*', 'Content-Type' => 'application/json')
      end
    end

    context "when given a path that doesn't map to any openapi file" do
      before do
        allow(app).to receive(:call).and_return(['500', {}, []])
        env['PATH_INFO'] = 'foobar.json'
      end

      it 'delegates error handling to the next middleware' do
        expect(response).to include('500')
      end
    end

    context 'when attempting to use path traversing on path info' do
      before do
        allow(app).to receive(:call).and_return(['500', {}, []])
        env['PATH_INFO'] = '../traverse-secret.yml'
      end

      it 'errors out and delegates error handling to the next middleware' do
        expect(response).to include('500')
      end
    end

    context 'when the env contains a specific openapi_root' do
      before do
        env['action_dispatch.request.path_parameters'] = { openapi_root: config.openapi_root }
      end

      it 'locates files at the provided openapi_root', :aggregate_failures do
        expect(response).to have_attributes(length: 3, first: '200')
        expect(response[1]).to include('Content-Type' => 'application/json')
        expect(response[2].join).to include('"openapi":"3.0.1"')
      end
    end

    context 'when an openapi_filter is configured' do
      before do
        config.openapi_filter = ->(openapi, env) { openapi['host'] = env['HTTP_HOST'] }
      end

      it 'applies the filter prior to serialization', :aggregate_failures do
        expect(response.length).to be(3)
        expect(response[2].join).to include('"host":"tempuri.org"')
      end
    end

    context 'when a path maps to a yaml openapi file' do
      before { env['PATH_INFO'] = 'v1/openapi.yml' }

      it 'returns contents of the openapi file', :aggregate_failures do
        expect(response).to have_attributes(length: 3, first: '200')
        expect(response[1]).to include('Content-Type' => 'text/yaml')
        expect(response[2].join).to include('title: API V1')
      end
    end
  end
end
