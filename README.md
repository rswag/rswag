rswag
=========
[![Build Status](https://travis-ci.org/rswag/rswag.svg?branch=master)](https://travis-ci.org/rswag/rswag)
[![Maintainability](https://api.codeclimate.com/v1/badges/1175b984edc4610f82ab/maintainability)](https://codeclimate.com/github/rswag/rswag/maintainability)

[Swagger](http://swagger.io) tooling for Rails API's. Generate beautiful API documentation, including a UI to explore and test operations, directly from your rspec integration tests.

Rswag extends rspec-rails "request specs" with a Swagger-based DSL for describing and testing API operations. You describe your API operations with a succinct, intuitive syntax, and it automaticaly runs the tests. Once you have green tests, run a rake task to auto-generate corresponding Swagger files and expose them as YAML or JSON endpoints. Rswag also provides an embedded version of the awesome [swagger-ui](https://github.com/swagger-api/swagger-ui) that's powered by the exposed file. This toolchain makes it seamless to go from integration specs, which youre probably doing in some form already, to living documentation for your API consumers.

And that's not all ...

Once you have an API that can describe itself in Swagger, you've opened the treasure chest of Swagger-based tools including a client generator that can be targeted to a wide range of popular platforms. See [swagger-codegen](https://github.com/swagger-api/swagger-codegen) for more details.

## Compatibility ##

|Rswag Version|Swagger (OpenAPI) Spec.|swagger-ui|
|----------|----------|----------|
|[master](https://github.com/rswag/rswag/tree/master)|2.0|3.18.2|
|[2.2.0](https://github.com/rswag/rswag/tree/2.2.0)|2.0|3.18.2|
|[1.6.0](https://github.com/rswag/rswag/tree/1.6.0)|2.0|2.2.5|

## Getting Started ##

1. Add this line to your applications _Gemfile_:

    ```ruby
    gem 'rswag'
    ```

    or if you like to avoid loading rspec in other bundler groups load the rswag-specs component separately.
    Note: Adding it to the :development group is not strictly necessary, but without it, generators and rake tasks must be preceded by RAILS_ENV=test.

    ```ruby
    # Gemfile
    gem 'rswag-api'
    gem 'rswag-ui'

    group :development, :test do
      gem 'rspec-rails'
      gem 'rswag-specs'
    end
    ```

2. Run the install generator

    ```ruby
    rails g rswag:install
    ```

    Or run the install generators for each package separately if you installed Rswag as separate gems, as indicated above:

    ```ruby
    rails g rswag:api:install
    rails g rswag:ui:install
    RAILS_ENV=test rails g rswag:specs:install
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

          response '406', 'unsupported accept header' do
            let(:'Accept') { 'application/foo' }
            run_test!
          end
        end
      end
    end
    ```

    There is also a generator which can help get you started `rails generate rspec:swagger API::MyController`


4. Generate the Swagger JSON file(s)

    ```ruby
    rake rswag:specs:swaggerize
    ```

    This common command is also aliased as `rake rswag`.

5. Spin up your app and check out the awesome, auto-generated docs at _/api-docs_!

## The rspec DSL ##

### Paths, Operations and Responses ###

If you've used [Swagger](http://swagger.io/specification) before, then the syntax should be very familiar. To describe your API operations, start by specifying a path and then list the supported operations (i.e. HTTP verbs) for that path. Path parameters must be surrounded by curly braces ({}). Within an operation block (see "post" or "get" in the example above), most of the fields supported by the [Swagger "Operation" object](http://swagger.io/specification/#operationObject) are available as methods on the example group. To list (and test) the various responses for an operation, create one or more response blocks. Again, you can reference the [Swagger "Response" object](http://swagger.io/specification/#responseObject) for available fields.

Take special note of the __run_test!__ method that's called within each response block. This tells rswag to create and execute a corresponding example. It builds and submits a request based on parameter descriptions and corresponding values that have been provided using the rspec "let" syntax. For example, the "post" description in the example above specifies a "body" parameter called "blog". It also lists 2 different responses. For the success case (i.e. the 201 response), notice how "let" is used to set the blog parameter to a value that matches the provided schema. For the failure case (i.e. the 422 response), notice how it's set to a value that does not match the provided schema. When the test is executed, rswag also validates the actual response code and, where applicable, the response body against the provided [JSON Schema](http://json-schema.org/documentation.html).

If you want to do additional validation on the response, pass a block to the __run_test!__ method:

```ruby
response '201', 'blog created' do
  run_test! do |response|
    data = JSON.parse(response.body)
    expect(data['title']).to eq('foo')
  end
end
```

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

### Null Values ###

This library is currently using JSON::Draft4 for validation of response models. It does not support null as a value. So you can add the property 'x-nullable' to a definition to allow null/nil values to pass.
```ruby
describe 'Blogs API' do
  path '/blogs' do
    post 'Creates a blog' do
      ...

      response '200', 'blog found' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            title: { type: :string },
            content: { type: :string, 'x-nullable': true }
          }
        ....
      end
    end
  end
end
```
*Note:* OAI v3 has a nullable property. Rswag will work to support this soon. This may have an effect on the need/use of custom extension to the draft. Do not use this property if you don't understand the implications.
<https://github.com/OAI/OpenAPI-Specification/issues/229#issuecomment-280376087>

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
        version: 'v1',
        description: 'This is the first version of my API'
      },
      basePath: '/api/v1'
    },

    'v2/swagger.yaml' => {
      openapi: '3.0.0',
      info: {
        title: 'API V2',
        version: 'v2',
        description: 'This is the second version of my API'
      },
      basePath: '/api/v2'
    }
  }
end
```

#### Supporting multiple versions of API ####
By default, the paths, operations and responses defined in your spec files will be associated with the first Swagger document in _swagger_helper.rb_. If your API has multiple versions, you should be using separate documents to describe each of them. In order to assign a file with a given version of API, you'll need to add the ```swagger_doc``` tag to each spec specifying its target document name:

```ruby
# spec/integration/v2/blogs_spec.rb
describe 'Blogs API', swagger_doc: 'v2/swagger.yaml' do

  path '/blogs' do
  ...

  path '/blogs/{id}' do
  ...
end
```

#### Formatting the description literals: ####
Swagger supports the Markdown syntax to format strings. This can be especially handy if you were to provide a long description of a given API version or endpoint. Use [this guide](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) for reference.

__NOTE:__ There is one difference between the official Markdown syntax and Swagger interpretation, namely tables. To create a table like this:

| Column1 | Collumn2 |
| ------- | -------- |
| cell1   | cell2    |

you should use the folowing syntax, making sure there are no whitespaces at the start of any of the lines:

```
&#13;
| Column1 | Collumn2 |&#13;
| ------- | -------- |&#13;
| cell1   | cell2    |&#13;
&#13;
```

### Specifying/Testing API Security ###

Swagger allows for the specification of different security schemes and their applicability to operations in an API. To leverage this in rswag, you define the schemes globally in _swagger_helper.rb_ and then use the "security" attribute at the operation level to specify which schemes, if any, are applicable to that operation. Swagger supports :basic, :apiKey and :oauth2 scheme types. See [the spec](http://swagger.io/specification/#security-definitions-object-109) for more info.

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/swagger'

  config.swagger_docs = {
    'v1/swagger.json' => {
      ...
      securityDefinitions: {
        basic: {
          type: :basic
        },
        apiKey: {
          type: :apiKey,
          name: 'api_key',
          in: :query
        }
      }
    }
  }
end

# spec/integration/blogs_spec.rb
describe 'Blogs API' do

  path '/blogs' do

    post 'Creates a blog' do
      tags 'Blogs'
      security [ basic: [] ]
      ...

      response '201', 'blog created' do
        let(:Authorization) { "Basic #{::Base64.strict_encode64('jsmith:jspass')}" }
        run_test!
      end

      response '401', 'authentication failed' do
        let(:Authorization) { "Basic #{::Base64.strict_encode64('bogus:bogus')}" }
        run_test!
      end
    end
  end
end
```

__NOTE:__ Depending on the scheme types, you'll be required to assign a corresponding parameter value with each example. For example, :basic auth is required above and so the :Authorization (header) parameter must be set accordingly

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

### Input Location for Rspec Tests ###

By default, rswag will search for integration tests in _spec/requests_, _spec/api_ and _spec/integration_. If you want to use tests from other locations, provide the PATTERN argument to rake:

```ruby
# search for tests in spec/swagger
rake rswag:specs:swaggerize PATTERN="spec/swagger/**/*_spec.rb"
```

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

### Enable generation examples from responses ###

To enable examples generation from responses add callback above run_test! like:
```ruby
after do |example|
  example.metadata[:response][:examples] = { 'application/json' => JSON.parse(response.body, symbolize_names: true) }
end
```
You need to disable --dry-run option for Rspec > 3

Add to config/environments/test.rb:
```ruby
RSpec.configure do |config|
  config.swagger_dry_run = false
end
```

### Running tests without documenting ###

If you want to use Rswag for testing without adding it to you swagger docs, you can provide the document tag:
```ruby
describe 'Blogs API' do
  path '/blogs/{blog_id}' do
    get 'Retrieves a blog' do
      # documentation is now disabled for this response only
      response 200, 'blog found', document: false do
        ...
```

You can also reenable documentation for specific responses only:
```ruby
# documentation is now disabled
describe 'Blogs API', document: false do
  path '/blogs/{blog_id}' do
    get 'Retrieves a blog' do
      # documentation is reenabled for this response only
      response 200, 'blog found', document: true do
        ...
      end

      response 401, 'special case' do
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

Note how the filter is passed the rack env for the current request. This provides a lot of flexibilty. For example, you can assign the "host" property (as shown) or you could inspect session information or an Authorization header and remove operations based on user permissions.

### Custom Headers for Swagger Files ###

You can specify custom headers for serving your generated Swagger JSON. For example you may want to force a specific charset for the 'Content-Type' header. You can configure a hash of headers to be sent with the request:

```ruby
Rswag::Api.configure do |c|
  ...
  
  c.swagger_headers = { 'Content-Type' => 'application/json; charset=UTF-8' }
end
```

Take care when overriding Content-Type if you serve both YAML and JSON files as it will no longer switch the Content-Type header correctly.


### Enable Swagger Endpoints for swagger-ui ###

You can update the _rswag-ui.rb_ initializer, installed with rswag-ui, to specify which Swagger endpoints should be available to power the documentation UI. If you're using rswag-api, these should correspond to the Swagger endpoints it exposes. When the UI is rendered, you'll see these listed in a drop-down to the top right of the page:

```ruby
Rswag::Ui.configure do |c|
  c.swagger_endpoint '/api-docs/v1/swagger.json', 'API V1 Docs'
  c.swagger_endpoint '/api-docs/v2/swagger.json', 'API V2 Docs'
end
```

### Enable Simple Basic Auth for swagger-ui

You can also update the _rswag-ui.rb_ initializer, installed with rswag-ui to specify a username and password should you want to keep your documentation private.

```ruby
Rswag::Ui.configure do |c|
  c.basic_auth_enabled = true
  c.basic_auth_credentials 'username', 'password'
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

The swagger-ui provides several options for customizing it's behavior, all of which are documented here https://github.com/swagger-api/swagger-ui/tree/2.x#swaggerui. If you need to tweak these or customize the overall look and feel of your swagger-ui, then you'll need to provide your own version of index.html. You can do this with the following generator.

```ruby
rails g rswag:ui:custom

```

This will add a local version that you can modify at _app/views/rswag/ui/home/index.html.erb_

### Serve UI Assets Directly from your Web Server

Rswag ships with an embedded version of the [swagger-ui](https://github.com/swagger-api/swagger-ui), which is a static collection of JavaScript and CSS files. These assets are served by the rswag-ui middleware. However, for optimal performance you may want to serve them directly from your web server (e.g. Apache or NGINX). To do this, you'll need to copy them to the web server root. This is the "public" folder in a typical Rails application.

```
bundle exec rake rswag:ui:copy_assets[public/api-docs]
```

__NOTE:__: The provided subfolder MUST correspond to the UI mount prefix - "api-docs" by default.
