require 'swagger_helper'

RSpec.describe 'Blogs API', type: :request, swagger_doc: 'v1/swagger.json' do
  let(:api_key) { 'fake_key' }

  before do
    allow(ActiveSupport::Deprecation).to receive(:warn) # Silence deprecation output from specs
  end

  path '/blogs' do
    post 'Creates a blog' do
      tags 'Blogs'
      description 'Creates a new blog from provided data'
      operationId 'createBlog'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :blog, in: :body, schema: { '$ref' => '#/definitions/blog' }

      let(:blog) { { title: 'foo', content: 'bar' } }

      response '201', 'blog created' do
        # schema '$ref' => '#/definitions/blog'
        run_test!
      end

      response '422', 'invalid request' do
        schema '$ref' => '#/definitions/errors_object'

        let(:blog) { { title: 'foo' } }
        run_test! do |response|
          expect(response.body).to include("can't be blank")
        end
      end
    end

    get 'Searches blogs' do
      tags 'Blogs'
      description 'Searches blogs by keywords'
      operationId 'searchBlogs'
      produces 'application/json'
      parameter name: :keywords, in: :query, type: 'string'

      let(:keywords) { 'foo bar' }

      response '200', 'success' do
        schema type: 'array', items: { '$ref' => '#/definitions/blog' }
      end

      response '406', 'unsupported accept header' do
        let(:'Accept') { 'application/foo' }
        run_test!
      end
    end
  end

  path '/blogs/flexible' do
    post 'Creates a blog flexible body' do
      tags 'Blogs'
      description 'Creates a flexible blog from provided data'
      operationId 'createFlexibleBlog'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :flexible_blog, in: :body, schema: {
        oneOf: [
          { '$ref' => '#/definitions/blog' },
          { '$ref' => '#/definitions/flexible_blog' }
        ]
      }

      let(:flexible_blog) { { blog: { headline: 'my headline', text: 'my text' } } }

      response '201', 'flexible blog created' do
        schema oneOf: [{ '$ref' => '#/definitions/blog' }, { '$ref' => '#/definitions/flexible_blog' }]
        run_test!
      end
    end
  end

  path '/blogs/{id}' do
    parameter name: :id, in: :path, type: :string

    let(:id) { blog.id }
    let(:blog) { Blog.create(title: 'foo', content: 'bar', thumbnail: 'thumbnail.png') }

    get 'Retrieves a blog' do
      tags 'Blogs'
      description 'Retrieves a specific blog by id'
      operationId 'getBlog'
      produces 'application/json'

      response '200', 'blog found' do
        header 'ETag', type: :string
        header 'Last-Modified', type: :string
        header 'Cache-Control', type: :string

        schema '$ref' => '#/definitions/blog'

        examples 'application/json' => {
          id: 1,
          title: 'Hello world!',
          content: 'Hello world and hello universe. Thank you all very much!!!',
          thumbnail: 'thumbnail.png'
        }

        let(:id) { blog.id }
        run_test!
      end

      response '404', 'blog not found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end

  path '/blogs/{id}/upload' do
    parameter name: :id, in: :path, type: :string

    let(:id) { blog.id }
    let(:blog) { Blog.create(title: 'foo', content: 'bar') }

    put 'Uploads a blog thumbnail' do
      tags 'Blogs'
      description 'Upload a thumbnail for specific blog by id'
      operationId 'uploadThumbnailBlog'
      consumes 'multipart/form-data'
      parameter name: :file, :in => :formData, :type => :file, required: true

      response '200', 'blog updated' do
        let(:file) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/thumbnail.png")) }
        run_test!
      end
    end
  end
end
