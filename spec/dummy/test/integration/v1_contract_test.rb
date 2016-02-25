require 'test_helper'
require 'swagger_rails/testing/test_helpers'

class V1ContractTest < ActionDispatch::IntegrationTest
  include SwaggerRails::TestHelpers
  swagger_doc 'v1/swagger.json'

  # TODO: improve DSL

  test 'Blogs API' do
    swagger_test '/blogs', 'post'

    swagger_test '/blogs', 'get'

    swagger_test '/blogs/{id}', 'get' do
      set id: Blog.last!.id
    end
  end
end
