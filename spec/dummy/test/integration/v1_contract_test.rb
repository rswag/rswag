require 'test_helper'
require 'swagger_rails/testing/test_helpers'

class V1ContractTest < ActionDispatch::IntegrationTest
  include SwaggerRails::TestHelpers

  swagger_doc 'v1/swagger.json'
  swagger_test_all
end
