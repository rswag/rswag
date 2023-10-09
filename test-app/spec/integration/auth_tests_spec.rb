# frozen_string_literal: true

require 'openapi_helper'

RSpec.describe 'Auth Tests API', type: :request, openapi_spec: 'v1/openapi.json' do
  path '/auth-tests/basic' do
    post 'Authenticates with basic auth' do
      tags 'Auth Tests'
      operationId 'testBasicAuth'
      security [basic_auth: []]

      response '204', 'Valid credentials' do
        let(:request_headers) { { "Authorization" => "Basic #{::Base64.strict_encode64('jsmith:jspass')}" } }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:request_headers) { { "Authorization" => "Basic #{::Base64.strict_encode64('foo:bar')}" } }
        run_test!
      end
    end
  end

  path '/auth-tests/api-key' do
    post 'Authenticates with an api key' do
      tags 'Auth Tests'
      operationId 'testApiKey'
      security [api_key: []]

      response '204', 'Valid credentials' do
        let(:request_params) { { "api_key" => 'foobar' } }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:request_params) { { "api_key" => 'barFoo' } }
        run_test!
      end
    end
  end

  path '/auth-tests/bearer' do
    post 'Authenticates with an api key' do
      tags 'Auth Tests'
      operationId 'testBearerToken'
      security [bearer: []]

      response '204', 'Valid credentials' do
        let(:Authorization) { 'Bearer foobar' }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:Authorization) { 'Bearer barFoo' }
        run_test!
      end
    end
  end

  path '/auth-tests/basic-and-api-key' do
    post 'Authenticates with basic auth and api key' do
      tags 'Auth Tests'
      operationId 'testBasicAndApiKey'
      security [{ basic_auth: [], api_key: [] }]

      response '204', 'Valid credentials' do
        let(:request_headers) { { "Authorization" => "Basic #{::Base64.strict_encode64('jsmith:jspass')}" } }
        let(:request_params) { { "api_key" => 'foobar' } }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:request_headers) { { "Authorization" => "Basic #{::Base64.strict_encode64('jsmith:jspass')}" } }
        let(:request_params) { { "api_key" => 'barFoo' } }
        run_test!
      end
    end
  end
end
