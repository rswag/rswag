require 'swagger_helper'

RSpec.describe 'Blogs API', type: :request, openapi_spec: 'v1/swagger.json' do
  let(:api_key) { 'fake_key' }

  before do
    # allow(Rswag::Specs.deprecator).to receive(:warn) # Silence deprecation output from specs
  end

  path '/blogs' do
    post 'Creates a blog' do
      tags 'Blogs'
      description 'Creates a new blog from provided data'
      operationId 'createBlog'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :blog, in: :body, schema: { '$ref' => '#/components/schemas/blog' }

      let(:blog) { { title: 'foo', content: 'bar', status: 'published' } }

      response '201', 'blog created' do
        # schema '$ref' => '#/definitions/blog'
        run_test!
      end

      response "422", "invalid request" do
        schema "$ref" => "#/components/schemas/errors_object"

        let(:blog) { {title: "foo"} }

        run_test!

        # Example to show custom specification description
        run_test!("returns a 422 response - with error for missing content") do |response|
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
      parameter name: :status, in: :query, getter: :blog_status,
                enum: { 'draft': 'Retrieves draft blogs', 'published': 'Retrieves published blogs', 'archived': 'Retrieves archived blogs' },
                description: 'Filter by status'

      before do
        Blog.create(title: 'foo', content: 'hello world', status: :published)
      end

      let(:keywords) { 'foo bar' }
      let(:blog_status) { 'published' }

      response '200', 'success' do
        schema type: 'array', items: { '$ref' => '#/components/schemas/blog' }

        run_test! do
          expect(JSON.parse(response.body).size).to eq(1)
        end
      end

      response '200', 'no content' do
        schema type: 'array', items: { '$ref' => '#/components/schemas/blog' }

        let(:blog_status) { 'invalid' }

        run_test! do
          expect(JSON.parse(response.body).size).to eq(0)
        end
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
        schema oneOf: [{ '$ref' => '#/components/schemas/blog' }, { '$ref' => '#/components/schemas/flexible_blog' }]
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

        schema '$ref' => '#/components/schemas/blog'

        #Legacy
        examples 'application/json' => {
          id: 1,
          title: 'Hello legacy world!',
          content: 'Hello legacy world and hello universe. Thank you all very much!!!',
          thumbnail: 'legacy-thumbnail.png'
        }

        example 'application/json', :blog_example_1, {
          id: 1,
          title: 'Hello world!',
          content: 'Hello world and hello universe. Thank you all very much!!!',
          thumbnail: 'thumbnail.png'
        }, "Summary of the example", "A longer description of a fine blog post about a wonderful universe!"

        example 'application/json', :blog_example_2, {
          id: 1,
          title: 'Another fine example!',
          content: 'Oh... what a fine example this is, indeed, a fine example!',
          thumbnail: 'thumbnail.png'
        }

        let(:id) { blog.id }

        run_test!

        context 'when openapi_strict_schema_validation is true' do
          run_test!(openapi_strict_schema_validation: true)
        end

        context 'when openapi_all_properties_required is true' do
          run_test!(openapi_all_properties_required: true)
        end

        context 'when openapi_no_additional_properties is true' do
          run_test!(openapi_no_additional_properties: true)
        end
      end

      response '404', 'blog not found' do
        let(:id) { 'invalid' }
        run_test!
      end

      response '200', 'blog found - openapi_strict_schema_validation = true', openapi_strict_schema_validation: true do
        schema '$ref' => '#/components/schemas/blog'

        let(:id) { blog.id }

        run_test!
      end

      response '200', 'blog found - openapi_all_properties_required = true', openapi_all_properties_required: true do
        schema '$ref' => '#/components/schemas/blog'

        let(:id) { blog.id }

        run_test!
      end

      response '200', 'blog found - openapi_no_additional_properties = true', openapi_no_additional_properties: true do
        schema '$ref' => '#/components/schemas/blog'

        let(:id) { blog.id }

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
      parameter(
        name: :file,
        description: "The content of the blog thumbnail",
        in: :formData,
        type: :file,
        required: true
      )

      response '200', 'blog updated' do
        let(:file) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/thumbnail.png")) }
        run_test!
      end
    end
  end
end
