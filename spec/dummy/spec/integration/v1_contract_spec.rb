require 'rails_helper'
require 'swagger_rails/testing/test_helpers'

describe 'V1 Contract' do
  include SwaggerRails::TestHelpers
  swagger_doc 'v1/swagger.json'

  # TODO: improve DSL

  it 'exposes an API for managing blogs' do
    swagger_test '/blogs', 'post'

    swagger_test '/blogs', 'get'

    swagger_test '/blogs/{id}', 'get' do
      set id: Blog.last!.id  
    end
  end
end
