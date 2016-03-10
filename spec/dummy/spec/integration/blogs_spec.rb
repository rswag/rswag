require 'rails_helper'

describe 'Blogs API', doc: 'blogs/v1' do

  path '/blogs' do

    operation 'post', 'creates a new blog' do
      consumes 'application/json'
      produces 'application/json'
      body :blog 

      let(:blog) { { title: 'foo', content: 'bar' } }

      response '201', 'valid request' do
        run_test!
      end

      response '422', 'invalid request' do
        let(:blog) { { title: 'foo' } }
        run_test!
      end
    end

    operation 'get', 'searches existing blogs' do
      produces 'application/json'

      response '200', 'valid request' do
        run_test!
      end
    end
  end

  path '/blogs/{id}' do
    operation 'get', 'retreives a specific blog' do
      produces 'application/json'
      parameter :id, 'path'

      response '200', 'blog found' do
        let(:blog) { Blog.create(title: 'foo', content: 'bar') }
        let(:id) { blog.id }
        run_test!
      end
    end
  end
end
