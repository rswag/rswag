rswag (formerly swagger_rails)
=========
[![Build Status](https://travis-ci.org/domaindrivendev/rswag.svg?branch=master)](https://travis-ci.org/domaindrivendev/rswag)

[Swagger](http://swagger.io) tooling for Rails API's. Generate beautiful API documentation, including a UI to explore and test operations, directly from your rspec integration tests.

Rswag extends rspec-rails "request specs" with a Swagger-based DSL for describing and testing API operations. You describe your API operations with a succinct, intuitive syntax, and it automaticaly runs the tests. Once you have green tests, run a rake task to auto-generate corresponding Swagger files and expose them as JSON endpoints. Rswag also provides an embedded version of the awesome [swagger-ui](https://github.com/swagger-api/swagger-ui) that's powered by the exposed JSON. This toolchain makes it seamless to go from integration specs, which youre probably doing in some form already, to living documentation for your API consumers.

And that's not all ...

Once you have an API that can describe itself in Swagger, you've opened the treasure chest of Swagger-based tools including a client generator that can be targeted to a wide range of popular platforms. See [swagger-codegen](https://github.com/swagger-api/swagger-codegen) for more details.

## Getting Started ##

1. Add this line to your applications _Gemfile_:

    ```ruby
    gem 'rswag'
    ```

2. Run the install generator

    ```ruby
    rails g rswag:install
    ```

3. Create an integration spec to describe and test your API.

    ```ruby
    # spec/integration/blogs_spec.rb
    require 'swagger_helper'

    describe 'Blogs API' do

      path '/blogs' do

        post 'Creates a blog' do
          tags 'Blogs'
          consumes 'application/json', 'application/xml'
          parameter name: :blog, in: :body, schema: {
            type: :object,
            properties: {
              title: { type: :string },
              content: { type: :string }
            },
            required: [ 'title', 'content' ]
          }

          response '201', 'blog created' do
            let(:blog) { { title: 'foo', content: 'bar' } }
            run_test!
          end

          response '422', 'invalid request' do
            let(:blog) { { title: 'foo' } }
            run_test!
          end
        end
      end

      path '/blogs/{id}' do

        get 'Retrieves a blog' do
          tags 'Blogs'
          produces 'application/json', 'application/xml'
          parameter name: :id, :in => :path, :type => :string

          response '200', 'blog found' do
            schema type: :object,
              properties: {
                id: { type: :integer },
                title: { type: :string },
                content: { type: :string }
              },
              required: [ 'id', 'title', 'content' ]

            let(:id) { Blog.create(title: 'foo', content: 'bar').id }
            run_test!
          end

          response '404', 'blog not found' do
            let(:id) { 'invalid' }
            run_test!
          end
        end
      end
    end
    ```

4. Generate the Swagger JSON file(s)

    ```ruby
    rake rswag:specs:swaggerize
    ```

5. Spin up your app and check out the awesome, auto-generated docs at _/api-docs_!

## The rspec DSL ##

### Paths, Operations and Responses ###

If you've used [Swagger](http://swagger.io/specification) before, then the syntax should be very familiar. To describe your API operations, start by specifying a path and then list the supported operations (i.e. HTTP verbs) for that path. Path parameters must be surrounded by curly braces ({}). Within an operation block (see "post" or "get" in the example above), most of the fields supported by the [Swagger "Operation" object](http://swagger.io/specification/#operationObject) are available as methods on the example group. To list (and test) the various responses for an operation, create one or more response blocks. Again, you can reference the [Swagger "Response" object](http://swagger.io/specification/#responseObject) for available fields.

Take special note of the __run_test!__ method that's called within each response block. This tells rswag to create and execute a corresponding example. It builds and submits a request based on parameter descriptions and corresponding values that have been provided using the rspec "let" syntax. For example, the "post" description in the example above specifies a "body" parameter called "blog". It also lists 2 different responses. For the success case (i.e. the 201 response), notice how "let" is used to set the blog parameter to a value that matches the provided schema. For the failure case (i.e. the 422 response), notice how it's set to a value that does not match the provided schema. When the test is executed, rswag also validates the actual response code and, where applicable, the response body against the provided [JSON Schema](http://json-schema.org/documentation.html).

If you'd like your specs to be a little more explicit about what's going on here, you can replace the call to __run_test!__ with equivalent "before" and "it" blocks:

```ruby
response '201', 'blog created' do
  let(:blog) { { title: 'foo', content: 'bar' } }

  before do |example|
    submit_request(example.metadata)
  end

  it 'returns a valid 201 response' do |example|
    assert_response_matches_metadata(example.metadata)
  end
end
```

### Global Metadata ###

In addition to paths, operations and responses, Swagger also supports global API metadata. When you install rswag, a file called _swagger_helper.rb_ is added to your spec folder. This is where you define one or more Swagger documents and provide global metadata. Again, the format is based on Swagger so most of the global fields supported by the top level ["Swagger" object](http://swagger.io/specification/#swaggerObject) can be provided with each document definition. As an example, you could define a Swagger document for each version of your API and in each case specify a title, version string and URL basePath:

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/swagger'

  config.swagger_docs = {
    'v1/swagger.json' => {
      swagger: '2.0',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      basePath: '/api/v1'
    },

    'v2/swagger.json' => {
      swagger: '2.0',
      info: {
        title: 'API V2',
        version: 'v2'
      },
      basePath: '/api/v2'
    }
  }
end
```

__NOTE__: By default, the paths, operations and responses defined in your spec files will be associated with the first Swagger document in _swagger_helper.rb_. If you're using multiple documents, you'll need to tag the individual specs with their target document name:

```ruby
# spec/integration/v2/blogs_spec.rb
describe 'Blogs API', swagger_doc: 'v2/swagger.json' do

  path '/blogs' do
  ...

  path '/blogs/{id}' do
  ...
end
```

## Configuration & Customization ##

The steps described above will get you up and running with minimal setup. However, rswag offers a lot of flexibility to customize as you see fit. Before exploring the various options, you'll need to be aware of it's different components. The following table lists each of them and the files that get added/updated as part of a standard install.

|Gem|Description|Added/Updated|
|---------|-----------|-------------|
|__rswag-specs__|Swagger-based DSL for rspec & accompanying rake task for generating Swagger files|_spec/swagger_helper.rb_|
|__rswag-api__  |Rails Engine that exposes your Swagger files as JSON endpoints|_config/initializers/rswag-api.rb, config/routes.rb_|
|__rswag-ui__   |Rails Engine that includes [swagger-ui](https://github.com/swagger-api/swagger-ui) and powers it from your Swagger endpoints|_config/initializers/rswag-ui.rb, config/routes.rb_|

### Output Location for Generated Swagger Files ###

You can adjust this in the _swagger_helper.rb_ that's installed with __rswag-specs__:

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/your-custom-folder-name'
  ...
end
```

__NOTE__: If you do change this, you'll also need to update the rswag-api.rb initializer (assuming you're using rswag-api). More on this later.

### Referenced Parameters and Schema Definitions ###

Swagger allows you to describe JSON structures inline with your operation descriptions OR as referenced globals. For example, you might have a standard response structure for all failed operations. Rather than repeating the schema in every operation spec, you can define it globally and provide a reference to it in each spec:

```ruby
# spec/swagger_helper.rb
config.swagger_docs = {
  'v1/swagger.json' => {
    swagger: '2.0',
    info: {
      title: 'API V1'
    },
    definitions: {
      errors_object: {
        type: 'object',
        properties: {
          errors: { '$ref' => '#/definitions/errors_map' }
        }
      },
      errors_map: {
        type: 'object',
        additionalProperties: {
          type: 'array',
          items: { type: 'string' }
        }
      }
    }
  }
}

# spec/integration/blogs_spec.rb
describe 'Blogs API' do

  path '/blogs' do

    post 'Creates a blog' do

      response 422, 'invalid request' do
        schema '$ref' => '#/definitions/errors_object'
  ...
end

# spec/integration/comments_spec.rb
describe 'Blogs API' do

  path '/blogs/{blog_id}/comments' do

    post 'Creates a comment' do

      response 422, 'invalid request' do
        schema '$ref' => '#/definitions/errors_object'
  ...
end
```

### Response headers ###

In Rswag, you could use `header` method inside the response block to specify header objects for this response. Rswag will validate your response headers with those header objects and inject them into the generated swagger file:

```ruby
# spec/integration/comments_spec.rb
describe 'Blogs API' do

  path '/blogs/{blog_id}/comments' do

    post 'Creates a comment' do

      response 422, 'invalid request' do
        header 'X-Rate-Limit-Limit', type: :integer, description: 'The number of allowed requests in the current period'
        header 'X-Rate-Limit-Remaining', type: :integer, description: 'The number of remaining requests in the current period'
  ...
end
```

### Response examples ###

You can provide custom response examples to the generated swagger file by calling the method `examples` inside the response block:

```ruby
# spec/integration/blogs_spec.rb
describe 'Blogs API' do

  path '/blogs/{blog_id}' do

    get 'Retrieves a blog' do

      response 200, 'blog found' do
        examples 'application/json' => {
            id: 1,
            title: 'Hello world!',
            content: '...'
          }
  ...
end
```

### Route Prefix for Swagger JSON Endpoints ###

The functionality to expose Swagger files, such as those generated by rswag-specs, as JSON endpoints is implemented as a Rails Engine. As with any Engine, you can change it's mount prefix in _routes.rb_:

```ruby
TestApp::Application.routes.draw do
  ...

  mount Rswag::Api::Engine => 'your-custom-prefix'
end
```

Assuming a Swagger file exists at &lt;swagger_root&gt;/v1/swagger.json, this configuration would expose the file as the following JSON endpoint:

```
GET http://<hostname>/your-custom-prefix/v1/swagger.json
```

### Root Location for Swagger Files ###

You can adjust this in the _rswag-api.rb_ initializer that's installed with __rspec-api__:

```ruby
Rswag::Api.configure do |c|
  c.swagger_root = Rails.root.to_s + '/your-custom-folder-name'
  ...
end
```

__NOTE__: If you're using rswag-specs to generate Swagger files, you'll want to ensure they both use the same &lt;swagger_root&gt;. The reason for separate settings is to maintain independence between the two gems. For example, you could install rswag-api independently and create your Swagger files manually.

### Dynamic Values for Swagger JSON ##

There may be cases where you need to add dynamic values to the Swagger JSON that's returned by rswag-api. For example, you may want to provide an explicit host name. Rather than hardcoding it, you can configure a filter that's executed prior to serializing every Swagger document:

```ruby
Rswag::Api.configure do |c|
  ...

  c.swagger_filter = lambda { |swagger, env| swagger['host'] = env['HTTP_HOST'] }
end
```

Note how the filter is passed the rack env for the current request. This provides a lot of flexibilty. For example, you can assign the "host" property (as shown) or you could inspect session information or an Authoriation header and remove operations based on user permissions.

### Enable Swagger Endpoints for swagger-ui ###

You can update the _rswag-ui.rb_ initializer, installed with rswag-ui, to specify which Swagger endpoints should be available to power the documentation UI. If you're using rswag-api, these should correspond to the Swagger endpoints it exposes. When the UI is rendered, you'll see these listed in a drop-down to the top right of the page:

```ruby
Rswag::Ui.configure do |c|
  c.swagger_endpoint '/api-docs/v1/swagger.json', 'API V1 Docs'
  c.swagger_endpoint '/api-docs/v2/swagger.json', 'API V2 Docs'
end
```

### Route Prefix for the swagger-ui ###

Similar to rswag-api, you can customize the swagger-ui path by changing it's mount prefix in _routes.rb_:

```ruby
TestApp::Application.routes.draw do
  ...

  mount Rswag::Api::Engine => 'api-docs'
  mount Rswag::Ui::Engine => 'your-custom-prefix'
end
```

### Customizing the swagger-ui ###

The swagger-ui provides several options for customizing it's behavior, all of which are documented here https://github.com/swagger-api/swagger-ui#swaggerui. If you need to tweak these or customize the overall look and feel of your swagger-ui, then you'll need to provide your own version of index.html. You can do this with the following generator.

```ruby
rails g rswag:ui:custom

```

This will add a local version that you can modify at _app/views/rswag/ui/home/index.html.erb_
