require 'swagger_helper'

describe 'Blogs API', swagger_doc: 'v1/swagger.json' do

  path '/blogs' do

    post 'creates a new blog' do
      operation_description 'Creates a new blog. You can provide detailed description here which will show up in Implementation Notes.'
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
    get 'retrieves a specific blog' do
      operation_description 'For the id passed in the path, it searches and retrieves a blog against that id. If blog not found it returns a 404'
      produces 'application/json'
      parameter :id, :in => :path, :type => :string, :required => true

      response '200', 'blog found' do
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
