require 'swagger_helper'

describe 'Auth Tests API', type: :request, swagger_doc: 'v1/swagger.json' do

  path '/auth-tests/basic' do
    post 'Authenticates with basic auth' do
      tags 'Auth Test'
      operationId 'testBasicAuth'
      security [ basic_auth: [] ]

      response '204', 'Valid credentials' do
        let(:Authorization) { "Basic #{::Base64.strict_encode64('jsmith:jspass')}" }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:Authorization) { "Basic #{::Base64.strict_encode64('foo:bar')}" }
        run_test!
      end
    end
  end
end
