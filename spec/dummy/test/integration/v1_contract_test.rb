require 'test_helper'
require 'swagger_rails/testing/test_helpers'

class V1ContractTest < ActionDispatch::IntegrationTest
  include SwaggerRails::TestHelpers

  swagger_doc 'v1/swagger.json'
#
#  test '/blogs post' do
#    swagger_test '/blogs', 'post'
#  end

  test '/blogs get' do
    blog = Blog.create(title: 'Test Blog', content: 'Hello World')

    swagger_test '/blogs', 'get'
  end
end
