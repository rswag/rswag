require 'swagger_helper'

describe 'Blogs API', type: :request, swagger_doc: 'v1/swagger.json' do
  let(:api_key) { 'fake_key' }

  path '/blogs' do
    post 'Creates a blog' do
      tags 'Blogs'
      description 'Creates a new blog from provided data'
      operationId 'createBlog'
      consumes 'application/json'
      parameter name: :blog, :in => :body, schema: { '$ref' => '#/definitions/blog' }

      response '201', 'blog created' do
        let(:blog) { { title: 'foo', content: 'bar' } }
        run_test!
      end

      response '422', 'invalid request' do
        schema '$ref' => '#/definitions/errors_object'

        let(:blog) { { title: 'foo' } }
        run_test!
      end
    end

    get 'Searches blogs' do
      tags 'Blogs'
      description 'Searches blogs by keywords'
      operationId 'searchBlogs'
      produces 'application/json'
      parameter name: :keywords, in: :query, type: 'string'

      response '200', 'success' do
        schema type: 'array', items: { '$ref' => '#/definitions/blog' }

        let(:keywords) { 'foo bar' }
        run_test!
      end
    end
  end

  path '/blogs/{id}' do
    parameter name: :id, :in => :path, :type => :string

    get 'Retrieves a blog' do
      tags 'Blogs'
      description 'Retrieves a specific blog by id'
      operationId 'getBlog'
      produces 'application/json'

      response '200', 'blog found' do
        schema '$ref' => '#/definitions/blog'

        let(:blog) { Blog.create(title: 'foo', content: 'bar') }
        let(:id) { blog.id }
        run_test!
      end

      response '404', 'blog not found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
