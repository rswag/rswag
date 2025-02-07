# frozen_string_literal: true

require 'spec_helper'

require 'rswag/api/middleware'
require 'rswag/api/configuration'

describe Rswag::Api::Middleware do
  let(:app) { double('app') }
  let(:openapi_root) { File.expand_path('fixtures/openapi', __dir__) }
  let(:config) do
    Rswag::Api::Configuration.new.tap { |c| c.openapi_root = openapi_root }
  end

  subject { described_class.new(app, config) }

  describe '#call(env)' do
    let(:response) { subject.call(env) }
    let(:env_defaults) do
      {
        'HTTP_HOST' => 'tempuri.org',
        'REQUEST_METHOD' => 'GET'
      }
    end

    context 'given a path that maps to an existing openapi file' do
      let(:env) { env_defaults.merge('PATH_INFO' => 'v1/openapi.json') }

      it 'returns a 200 status' do
        expect(response.length).to eql(3)
        expect(response.first).to eql('200')
      end

      it 'returns contents of the openapi file' do
        expect(response.length).to eql(3)
        expect(response[1]).to include('Content-Type' => 'application/json')
        expect(response[2].join).to include('"title":"API V1"')
      end

      context 'configured with a Pathname similar to `Rails.root.join("openapi")`' do
        let(:openapi_root_pathname) { Pathname.new(openapi_root) }

        before { config.openapi_root = openapi_root_pathname }

        it 'returns a 200 status' do
          expect(response.length).to eql(3)
          expect(response.first).to eql('200')
        end
      end
    end

    context 'when openapi_headers is configured' do
      let(:env) { env_defaults.merge('PATH_INFO' => 'v1/openapi.json') }

      context 'replacing the default content type header' do
        before do
          config.openapi_headers = { 'Content-Type' => 'application/json; charset=UTF-8' }
        end
        it 'returns a 200 status' do
          expect(response.length).to eql(3)
          expect(response.first).to eql('200')
        end

        it 'applies the headers to the response' do
          expect(response[1]).to include('Content-Type' => 'application/json; charset=UTF-8')
        end
      end

      context 'adding an additional header' do
        before do
          config.openapi_headers = { 'Access-Control-Allow-Origin' => '*' }
        end
        it 'returns a 200 status' do
          expect(response.length).to eql(3)
          expect(response.first).to eql('200')
        end

        it 'applies the headers to the response' do
          expect(response[1]).to include('Access-Control-Allow-Origin' => '*')
        end

        it 'keeps the default header' do
          expect(response[1]).to include('Content-Type' => 'application/json')
        end
      end
    end

    context "given a path that doesn't map to any openapi file" do
      let(:env) { env_defaults.merge('PATH_INFO' => 'foobar.json') }

      before do
        allow(app).to receive(:call).and_return(['500', {}, []])
      end

      it 'delegates to the next middleware' do
        expect(response).to include('500')
      end
    end

    context 'Disallow path traversing on path info' do
      let(:env) { env_defaults.merge('PATH_INFO' => '../traverse-secret.yml') }

      before do
        allow(app).to receive(:call).and_return(['500', {}, []])
      end

      it 'delegates to the next middleware' do
        expect(response).to include('500')
      end
    end

    context 'when the env contains a specific openapi_root' do
      let(:env) do
        env_defaults.merge(
          'PATH_INFO' => 'v1/openapi.json',
          'action_dispatch.request.path_parameters' => {
            openapi_root: openapi_root
          }
        )
      end

      it 'locates files at the provided openapi_root' do
        expect(response.length).to eql(3)
        expect(response[1]).to include('Content-Type' => 'application/json')
        expect(response[2].join).to include('"openapi":"3.0.1"')
      end
    end

    context 'when the env contains a specific openapi_root' do
      let(:env) do
        env_defaults.merge(
          'PATH_INFO' => 'v1/openapi.json',
          'action_dispatch.request.path_parameters' => {
            openapi_root: openapi_root
          }
        )
      end

      it 'locates files at the provided openapi_root' do
        expect(response.length).to eql(3)
        expect(response[1]).to include('Content-Type' => 'application/json')
        expect(response[2].join).to include('"openapi":"3.0.1"')
      end
    end

    context 'when a openapi_filter is configured' do
      before do
        config.openapi_filter = ->(openapi, env) { openapi['host'] = env['HTTP_HOST'] }
      end
      let(:env) { env_defaults.merge('PATH_INFO' => 'v1/openapi.json') }

      it 'applies the filter prior to serialization' do
        expect(response.length).to eql(3)
        expect(response[2].join).to include('"host":"tempuri.org"')
      end
    end

    context 'when a path maps to a yaml openapi file' do
      let(:env) { env_defaults.merge('PATH_INFO' => 'v1/openapi.yml') }

      it 'returns a 200 status' do
        expect(response.length).to eql(3)
        expect(response.first).to eql('200')
      end

      it 'returns contents of the openapi file' do
        expect(response.length).to eql(3)
        expect(response[1]).to include('Content-Type' => 'text/yaml')
        expect(response[2].join).to include('title: API V1')
      end
    end
  end
end
