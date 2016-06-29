require 'swagger_helper'

describe 'Blogs API', swagger_doc: 'v1/swagger.json' do

  path '/blogs' do

    post 'creates a new blog' do
      consumes 'application/json'
      produces 'application/json'
      parameter :blog, :in => :body, schema: {
        :type => :object,
        :properties => {
          title: { type: 'string' },
          content: { type: 'string' }
        }
      }

      response '201', 'valid request' do
        let(:blog) { { title: 'foo', content: 'bar' } }
        run_test!
      end

      response '422', 'invalid request' do
        let(:blog) { { title: 'foo' } }
        run_test!
      end
    end

    get 'searches existing blogs' do
      produces 'application/json'

      response '200', 'valid request' do
        run_test!
      end
    end
  end

  path '/blogs/{id}' do
    get 'retreives a specific blog' do
      produces 'application/json'
      parameter :id, :in => :path, :type => :string

      response '200', 'blog found' do
        let(:blog) { Blog.create(title: 'foo', content: 'bar') }
        let(:id) { blog.id }
        run_test!
      end
    end
  end
end
