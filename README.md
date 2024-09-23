<!-- cspell:ignore allof anyof oneof specifyingtesting -->

rswag
=========
[![Build Status](https://github.com/rswag/rswag/actions/workflows/ruby.yml/badge.svg?branch=master)](https://github.com/rswag/rswag/actions/workflows/ruby.yml?query=branch%3Amaster+)
[![Maintainability](https://api.codeclimate.com/v1/badges/1175b984edc4610f82ab/maintainability)](https://codeclimate.com/github/rswag/rswag/maintainability)

OpenApi 3.0 and Swagger 2.0 compatible!

Seeking maintainers! Got a pet-bug that needs fixing? Just let us know in your issue/pr that you'd like to step up to help.

Rswag extends rspec-rails "request specs" with a Swagger-based DSL for describing and testing API operations. You describe your API operations with a succinct, intuitive syntax, and it automatically runs the tests. Once you have green tests, run a rake task to auto-generate corresponding Swagger files and expose them as YAML or JSON endpoints. Rswag also provides an embedded version of the awesome [swagger-ui](https://github.com/swagger-api/swagger-ui) that's powered by the exposed file. This toolchain makes it seamless to go from integration specs, which you're probably doing in some form already, to living documentation for your API consumers.

Api Rswag creates [Swagger](http://swagger.io) tooling for Rails API's. Generate beautiful API documentation, including a UI to explore and test operations, directly from your rspec integration tests.


And that's not all ...

Once you have an API that can describe itself in Swagger, you've opened the treasure chest of Swagger-based tools including a client generator that can be targeted to a wide range of popular platforms. See [swagger-codegen](https://github.com/swagger-api/swagger-codegen) for more details.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
**Table of Contents**

- [rswag](#rswag)
  - [Getting Started](#getting-started)
  - [The rspec DSL](#the-rspec-dsl)
    - [Paths, Operations and Responses](#paths-operations-and-responses)
    - [Null Values](#null-values)
    - [Support for oneOf, anyOf or AllOf schemas](#support-for-oneof-anyof-or-allof-schemas)
    - [Global Metadata](#global-metadata)
      - [Supporting multiple versions of API](#supporting-multiple-versions-of-api)
      - [Formatting the description literals:](#formatting-the-description-literals)
    - [Specifying/Testing API Security](#specifyingtesting-api-security)
  - [Configuration & Customization](#configuration--customization)
    - [Output Location for Generated Swagger Files](#output-location-for-generated-swagger-files)
    - [Input Location for Rspec Tests](#input-location-for-rspec-tests)
    - [Referenced Parameters and Schema Definitions](#referenced-parameters-and-schema-definitions)
    - [Request examples](#request-examples)
    - [Response headers](#response-headers)
      - [Nullable or Optional Response Headers](#nullable-or-optional-response-headers)
    - [Response examples](#response-examples)
    - [Enable auto generation examples from responses](#enable-auto-generation-examples-from-responses)
      - [Dry Run Option](#dry-run-option)
      - [Running tests without documenting](#running-tests-without-documenting)
        - [rswag helper methods](#rswag-helper-methods)
    - [Route Prefix for Swagger JSON Endpoints](#route-prefix-for-swagger-json-endpoints)
    - [Root Location for Swagger Files](#root-location-for-swagger-files)
    - [Dynamic Values for Swagger JSON](#dynamic-values-for-swagger-json)
    - [Custom Headers for Swagger Files](#custom-headers-for-swagger-files)
    - [Enable Swagger Endpoints for swagger-ui](#enable-swagger-endpoints-for-swagger-ui)
    - [Enable Simple Basic Auth for swagger-ui](#enable-simple-basic-auth-for-swagger-ui)
    - [Route Prefix for the swagger-ui](#route-prefix-for-the-swagger-ui)
    - [Customizing the swagger-ui](#customizing-the-swagger-ui)
    - [Serve UI Assets Directly from your Web Server](#serve-ui-assets-directly-from-your-web-server)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



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
There is also a generator which can help get you started `rails generate rspec:swagger API::MyController`

    ```ruby
    # spec/requests/blogs_spec.rb
    require 'swagger_helper'

    describe 'Blogs API' do

      path '/blogs' do

        post 'Creates a blog' do
          tags 'Blogs'
          consumes 'application/json'
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
          tags 'Blogs', 'Another Tag'
          produces 'application/json', 'application/xml'
          parameter name: :id, in: :path, type: :string
          request_body_example value: { some_field: 'Foo' }, name: 'basic', summary: 'Request example description'

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
By default, the above command will create spec under _spec/requests_ folder. You can pass an option to change this default path as in `rails generate rspec:swagger API::BlogsController --spec_path integration`.
This will create the spec file _spec/integration/blogs_spec.rb_

4. Generate the Swagger JSON file(s)

    ```ruby
    rake rswag:specs:swaggerize
    ```

    This common command is also aliased as `rake rswag`.

    Or if you installed your gems separately:
    ```
    RAILS_ENV=test rails rswag
    ```

5. Spin up your app and check out the awesome, auto-generated docs at _/api-docs_!

## The rspec DSL ##

### Paths, Operations and Responses ###

If you've used [Swagger](http://swagger.io/specification) before, then the syntax should be very familiar. To describe your API operations, start by specifying a path and then list the supported operations (i.e. HTTP verbs) for that path. Path parameters must be surrounded by curly braces ({}). Within an operation block (see "post" or "get" in the example above), most of the fields supported by the [Swagger "Operation" object](http://swagger.io/specification/#operationObject) are available as methods on the example group. To list (and test) the various responses for an operation, create one or more response blocks. Again, you can reference the [Swagger "Response" object](http://swagger.io/specification/#responseObject) for available fields.

Take special note of the __run_test!__ method that's called within each response block. This tells rswag to create and execute a corresponding example. It builds and submits a request based on parameter descriptions and corresponding values that have been provided using the rspec "let" syntax. For example, the "post" description in the example above specifies a "body" parameter called "blog". It also lists 2 different responses. For the success case (i.e. the 201 response), notice how "let" is used to set the blog parameter to a value that matches the provided schema. For the failure case (i.e. the 422 response), notice how it's set to a value that does not match the provided schema. When the test is executed, rswag also validates the actual response code and, where applicable, the response body against the provided [JSON Schema](https://json-schema.org/specification).

If you want to add metadata to the example, you can pass keyword arguments to the __run_test!__ method:

```ruby
# to run particular test case
response '201', 'blog created' do
  run_test! focus: true
end

# to write vcr cassette
response '201', 'blog created' do
  run_test! vcr: true
end
```

If you want to customize the description of the generated specification, a description can be passed to **run_test!**

```ruby
response '201', 'blog created' do
  run_test! "custom spec description"
end
```

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

Also note that the examples generated with __run_test!__ are tagged with the `:rswag` so they can easily be filtered. E.g. `rspec --tag rswag`

### date-time in query parameters

Input sent in queries of Rspec tests is HTML safe, including date-time strings.

```ruby
parameter name: :date_time, in: :query, type: :string

response '200', 'blog found' do
  let(:date_time) { DateTime.new(2001, 2, 3, 4, 5, 6, '-7').to_s }

  run_test! do
    expect(request[:path]).to eq('/blogs?date_time=2001-02-03T04%3A05%3A06-07%3A00')
  end
end
```

### Enum description ###
If you want to output a description of each enum value, the description can be passed to each value:
```ruby
parameter name: :status, in: :query, getter: :blog_status,
          enum: { 'draft': 'Retrieves draft blogs', 'published': 'Retrieves published blogs', 'archived': 'Retrieves archived blogs' },
          description: 'Filter by status'

response '200', 'success' do
  let(:blog_status) { 'published' }

  run_test!
end
```

### Schema validations

#### Strict (deprecated)
It validates required properties and disallows additional properties in response body.
To enable, you can set the option `openapi_strict_schema_validation` to true.
It is equal to `openapi_no_additional_properties: true` and `openapi_all_properties_required: true`
**Important** If you would like to keep validation of required properties but allow additional properties, you can set the `openapi_strict_schema_validation` option to `false` and set `openapi_all_properties_required` to `true` and `openapi_no_additional_properties` to `false`.

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.openapi_strict_schema_validation = true # default false
end
```

or set the option per individual example:

```ruby
# using in run_test!
describe 'Blogs API' do
  path '/blogs' do
    post 'Creates a blog' do
      ...
      response '201', 'blog created' do
        let(:blog) { { title: 'foo', content: 'bar' } }

        run_test!(openapi_strict_schema_validation: true)
      end
    end
  end
end

# using in response block
describe 'Blogs API' do
  path '/blogs' do
    post 'Creates a blog' do
      ...

      response '201', 'blog created', openapi_strict_schema_validation: true do
        let(:blog) { { title: 'foo', content: 'bar' } }

        run_test!
      end
    end
  end
end

# using in an explicit example
describe 'Blogs API' do
  path '/blogs' do
    post 'Creates a blog' do
      ...
      response '201', 'blog created' do
        let(:blog) { { title: 'foo', content: 'bar' } }

        before do |example|
          submit_request(example.metadata)
        end

        it 'returns a valid 201 response', openapi_strict_schema_validation: true do |example|
          assert_response_matches_metadata(example.metadata)
        end
      end
    end
  end
end
```

#### Additional properties
If you want to disallow additional properties in response body, you can set the option `openapi_no_additional_properties` to true:

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.openapi_no_additional_properties = true # default false
end
```

You can set similarly the option per individual example as shown in Strict (deprecated) sections.

#### All required properties
If you want to disallow missing required properties in response body, you can set the `openapi_all_properties_required` option to true:
**Important** it will allow the additional properties

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.openapi_all_properties_required = true # default false
end
```

You can set similarly the option per individual example as shown in Strict (deprecated) sections.

### Null Values ###

This library is currently using JSON::Draft4 for validation of response models. Nullable properties can be supported with the non-standard property 'x-nullable' to a definition to allow null/nil values to pass. Or you can add the new standard ```nullable``` property to a definition.
```ruby
describe 'Blogs API' do
  path '/blogs' do
    post 'Creates a blog' do
      ...

      response '200', 'blog found' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            title: { type: :string, nullable: true }, # preferred syntax
            content: { type: :string, 'x-nullable': true } # legacy syntax, but still works
          }
        ....
      end
    end
  end
end
```

### Support for oneOf, anyOf or AllOf schemas ###

Open API 3.0 now supports more flexible schema validation with the ```oneOf```, ```anyOf``` and ```allOf``` directives. rswag will handle these definitions and validate them properly.


Notice the ```schema``` inside the ```response``` section. Placing a ```schema``` method inside the response will validate (and fail the tests)
if during the integration test run the endpoint response does not match the response schema. This test validation can handle anyOf and allOf as well. See below:

```ruby

  path '/blogs/flexible' do
    post 'Creates a blog flexible body' do
      tags 'Blogs'
      description 'Creates a flexible blog from provided data'
      operationId 'createFlexibleBlog'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :blog, in: :body, schema: {
          oneOf: [
            { '$ref' => '#/components/schemas/blog' },
            { '$ref' => '#/components/schemas/flexible_blog' }
          ]
        }

      response '201', 'flexible blog created' do
        schema oneOf: [{ '$ref' => '#/components/schemas/blog' }, { '$ref' => '#/components/schemas/flexible_blog' }]
        run_test!
      end
    end
  end

```
This automatic schema validation is a powerful feature of rswag.

### Global Metadata ###

In addition to paths, operations and responses, Swagger also supports global API metadata. When you install rswag, a file called _swagger_helper.rb_ is added to your spec folder. This is where you define one or more Swagger documents and provide global metadata. Again, the format is based on Swagger so most of the global fields supported by the top level ["Swagger" object](http://swagger.io/specification/#swaggerObject) can be provided with each document definition. As an example, you could define a Swagger document for each version of your API and in each case specify a title, version string. In Open API 3.0 the pathing and server definitions have changed a bit [Swagger host/basePath](https://swagger.io/docs/specification/api-host-and-base-path/):

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.openapi_root = Rails.root.to_s + '/swagger'

  config.openapi_specs = {
    'v1/swagger.json' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1',
        description: 'This is the first version of my API'
      },
      servers: [
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
                default: 'www.example.com'
            }
          }
        }
      ]
    },

    'v2/swagger.json' => {
      openapi: '3.0.1',
      info: {
        title: 'API V2',
        version: 'v2',
        description: 'This is the second version of my API'
      },
      servers: [
        {
          url: '{protocol}://{defaultHost}',
          variables: {
            protocol: {
              default: :https
            },
            defaultHost: {
                default: 'www.example.com'
            }
          }
        }
      ]
    }
  }
end
```

#### Supporting multiple versions of API ####
By default, the paths, operations and responses defined in your spec files will be associated with the first Swagger document in _swagger_helper.rb_. If your API has multiple versions, you should be using separate documents to describe each of them. In order to assign a file with a given version of API, you'll need to add the ```openapi_spec``` tag to each spec specifying its target document name:

```ruby
# spec/requests/v2/blogs_spec.rb
describe 'Blogs API', openapi_spec: 'v2/swagger.yaml' do

  path '/blogs' do
  ...

  path '/blogs/{id}' do
  ...
end
```

#### Supporting YAML format ####

By default, the swagger docs are generated in JSON format. If you want to generate them in YAML format, you can specify the swagger format in the swagger_helper.rb file:

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.openapi_root = Rails.root.to_s + '/swagger'

  # Use if you want to see which test is running
  # config.formatter = :documentation

  # Generate swagger docs in YAML format
  config.openapi_format = :yaml

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1',
        description: 'This is the first version of my API'
      },
      servers: [
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
                default: 'www.example.com'
            }
          }
        }
      ]
    },
  }
end
```

#### Formatting the description literals: ####
Swagger supports the Markdown syntax to format strings. This can be especially handy if you were to provide a long description of a given API version or endpoint. Use [this guide](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) for reference.

__NOTE:__ There is one difference between the official Markdown syntax and Swagger interpretation, namely tables. To create a table like this:

| Column1 | Column2 |
| ------- | ------- |
| cell1   | cell2   |

you should use the following syntax, making sure there is no whitespace at the start of any of the lines:

```
&#13;
| Column1 | Column2 | &#13; |
| ------- | ------- |&#13;
| cell1   | cell2    |&#13;
&#13;
```

### Specifying/Testing API Security ###

Swagger allows for the specification of different security schemes and their applicability to operations in an API.
To leverage this in rswag, you define the schemes globally in _swagger_helper.rb_ and then use the "security" attribute at the operation level to specify which schemes, if any, are applicable to that operation.
Swagger supports :basic, :bearer, :apiKey and :oauth2 and :openIdConnect scheme types. See [the spec](https://swagger.io/docs/specification/authentication/) for more info, as this underwent major changes between Swagger 2.0 and Open API 3.0

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.openapi_root = Rails.root.to_s + '/swagger'

  config.openapi_specs = {
    'v1/swagger.json' => {
      ...  # note the new Open API 3.0 compliant security structure here, under "components"
      components: {
        securitySchemes: {
          basic_auth: {
            type: :http,
            scheme: :basic
          },
          api_key: {
            type: :apiKey,
            name: 'api_key',
            in: :query
          }
        }
      }
    }
  }
end

# spec/requests/blogs_spec.rb
describe 'Blogs API' do

  path '/blogs' do

    post 'Creates a blog' do
      tags 'Blogs'
      security [ basic_auth: [] ]
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

# example of documenting an endpoint that handles basic auth and api key based security
describe 'Auth examples API' do
  path '/auth-tests/basic-and-api-key' do
    post 'Authenticates with basic auth and api key' do
      tags 'Auth Tests'
      operationId 'testBasicAndApiKey'
      security [{ basic_auth: [], api_key: [] }]

      response '204', 'Valid credentials' do
        let(:Authorization) { "Basic #{::Base64.strict_encode64('jsmith:jspass')}" }
        let(:api_key) { 'foobar' }
        run_test!
      end

      response '401', 'Invalid credentials' do
        let(:Authorization) { "Basic #{::Base64.strict_encode64('jsmith:jspass')}" }
        let(:api_key) { 'bar-foo' }
        run_test!
      end
    end
  end
end


```

__NOTE:__ Depending on the scheme types, you'll be required to assign a corresponding parameter value with each example.
For example, :basic auth is required above and so the :Authorization (header) parameter must be set accordingly

## Configuration & Customization ##

The steps described above will get you up and running with minimal setup. However, rswag offers a lot of flexibility to customize as you see fit. Before exploring the various options, you'll need to be aware of its different components. The following table lists each of them and the files that get added/updated as part of a standard install.

| Gem             | Description                                                                                                                  | Added/Updated                                        |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| __rswag-specs__ | Swagger-based DSL for rspec & accompanying rake task for generating Swagger files                                            | _spec/swagger_helper.rb_                             |
| __rswag-api__   | Rails Engine that exposes your Swagger files as JSON endpoints                                                               | _config/initializers/rswag_api.rb, config/routes.rb_ |
| __rswag-ui__    | Rails Engine that includes [swagger-ui](https://github.com/swagger-api/swagger-ui) and powers it from your Swagger endpoints | _config/initializers/rswag-ui.rb, config/routes.rb_  |

### Output Location for Generated Swagger Files ###

You can adjust this in the _swagger_helper.rb_ that's installed with __rswag-specs__:

```ruby
# spec/swagger_helper.rb
RSpec.configure do |config|
  config.openapi_root = Rails.root.to_s + '/your-custom-folder-name'
  ...
end
```

__NOTE__: If you do change this, you'll also need to update the rswag_api.rb initializer (assuming you're using rswag-api). More on this later.

### Input Location for Rspec Tests ###

By default, rswag will search for integration tests in _spec/requests_, _spec/api_ and _spec/integration_. If you want to use tests from other locations, provide the PATTERN argument to rake:

```ruby
# search for tests in spec/swagger
rake rswag:specs:swaggerize PATTERN="spec/swagger/**/*_spec.rb"
```

### Additional rspec options

You can add additional rspec parameters using the ADDITIONAL_RSPEC_OPTS env variable:

```ruby
# Only include tests tagged "rswag"
rake rswag:specs:swaggerize ADDITIONAL_RSPEC_OPTS="--tag rswag"
```

### Referenced Parameters and Schema Definitions ###

Swagger allows you to describe JSON structures inline with your operation descriptions OR as referenced globals.
For example, you might have a standard response structure for all failed operations.
Again, this is a structure that changed since swagger 2.0. Notice the new "schemas" section for these.
Rather than repeating the schema in every operation spec, you can define it globally and provide a reference to it in each spec:

```ruby
# spec/swagger_helper.rb
config.openapi_specs = {
  'v1/swagger.json' => {
    openapi: '3.0.0',
    info: {
      title: 'API V1'
    },
    components: {
      schemas: {
        errors_object: {
          type: 'object',
          properties: {
            errors: { '$ref' => '#/components/schemas/errors_map' }
          }
        },
        errors_map: {
          type: 'object',
          additionalProperties: {
            type: 'array',
            items: { type: 'string' }
          }
        },
        blog: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            title: { type: 'string' },
            content: { type: 'string', nullable: true },
            thumbnail: { type: 'string', nullable: true }
          },
          required: %w[id title]
        },
        new_blog: {
          type: 'object',
          properties: {
            title: { type: 'string' },
            content: { type: 'string', nullable: true },
            thumbnail: { type: 'string', format: 'binary', nullable: true }
          },
          required: %w[title]
        }
      }
    }
  }
}

# spec/requests/blogs_spec.rb
describe 'Blogs API' do

  path '/blogs' do

    post 'Creates a blog' do

      parameter name: :new_blog, in: :body, schema: { '$ref' => '#/components/schemas/new_blog' }

      response 422, 'invalid request' do
        schema '$ref' => '#/components/schemas/errors_object'
  ...
end

# spec/requests/comments_spec.rb
describe 'Blogs API' do

  path '/blogs/{blog_id}/comments' do

    post 'Creates a comment' do

      response 422, 'invalid request' do
        schema '$ref' => '#/components/schemas/errors_object'
  ...
end
```

### Request examples ###

```ruby
# spec/integration/blogs_spec.rb
describe 'Blogs API' do

  path '/blogs/{blog_id}' do

    get 'Retrieves a blog' do

      request_body_example value: { some_field: 'Foo' }, name: 'request_example_1', summary: 'A request example'

      response 200, 'blog found' do
        ...
```

to use the actual request from the spec as the example:

```ruby
config.after(:each, operation: true, use_as_request_example: true) do |spec|
  spec.metadata[:operation][:request_examples] ||= []

  example = {
    value: JSON.parse(request.body.string, symbolize_names: true),
    name: 'request_example_1',
    summary: 'A request example'
  }

  spec.metadata[:operation][:request_examples] << example
end
```

### Response headers ###

In Rswag, you could use `header` method inside the response block to specify header objects for this response.
Rswag will validate your response headers with those header objects and inject them into the generated swagger file:

```ruby
# spec/requests/comments_spec.rb
describe 'Blogs API' do

  path '/blogs/{blog_id}/comments' do

    post 'Creates a comment' do

      response 422, 'invalid request' do
        header 'X-Rate-Limit-Limit', schema: { type: :integer }, description: 'The number of allowed requests in the current period'
        header 'X-Rate-Limit-Remaining', schema: { type: :integer }, description: 'The number of remaining requests in the current period'
  ...
end
```

#### Nullable or Optional Response Headers ####

You can include `nullable` or `required` to specify whether a response header must be present or may be null. When `nullable` is not included, the headers validation validates that the header response is non-null. When `required` is not included, the headers validation validates the the header response is passed.

```ruby
# spec/integration/comments_spec.rb
describe 'Blogs API' do

  path '/blogs/{blog_id}/comments' do

    get 'Gets a list of comments' do

      response 200, 'blog found' do
        header 'X-Cursor', schema: { type: :string, nullable: true }, description: 'The cursor to get the next page of comments.'
        header 'X-Per-Page', schema: { type: :integer }, required: false, description: 'The number of comments per page.'
  ...
end
```

### Response examples ###

You can provide custom response examples to the generated swagger file by calling the method `examples` inside the response block:
However, auto generated example responses are now enabled by default in rswag. See below.

```ruby
# spec/requests/blogs_spec.rb
describe 'Blogs API' do

  path '/blogs/{blog_id}' do

    get 'Retrieves a blog' do

      response 200, 'blog found' do
        example 'application/json', :example_key, {
            id: 1,
            title: 'Hello world!',
            content: '...'
          }
        example 'application/json', :example_key_2, {
            id: 1,
            title: 'Hello world!',
            content: '...'
          }, "Summary of the example", "Longer description of the example"
  ...
end
```


### Enable auto generation examples from responses ###


To enable examples generation from responses add callback above run_test! like:

```ruby
after do |example|
  content = example.metadata[:response][:content] || {}
  example_spec = {
    "application/json"=>{
      examples: {
        test_example: {
          value: JSON.parse(response.body, symbolize_names: true)
        }
      }
    }
  }
  example.metadata[:response][:content] = content.deep_merge(example_spec)
end
```

#### Dry Run Option ####

The `--dry-run` option is enabled by default for Rspec 3, but if you need to
disable it you can use the environment variable `RSWAG_DRY_RUN=0` during the
generation command or add the following to your `config/environments/test.rb`:

```ruby
RSpec.configure do |config|
  config.rswag_dry_run = false
end
```

#### Running tests without documenting ####

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

##### rswag helper methods #####
<!--
There are some helper methods to help with documenting request bodies.
```ruby
describe 'Blogs API', type: :request, openapi_spec: 'v1/swagger.json' do
  let(:api_key) { 'fake_key' }

  path '/blogs' do
    post 'Creates a blog' do
      tags 'Blogs'
      description 'Creates a new blog from provided data'
      operationId 'createBlog'
      consumes 'application/json'
      produces 'application/json'

      request_body_json schema: { '$ref' => '#/components/schemas/blog' },
                        examples: :blog

      request_body_text_plain
      request_body_xml schema: { '$ref' => '#/components/schemas/blog' }

      let(:blog) { { blog: { title: 'foo', content: 'bar' } } }

      response '201', 'blog created' do
        schema '$ref' => '#/components/schemas/blog'
        run_test!
      end

      response '422', 'invalid request' do
        schema '$ref' => '#/components/schemas/errors_object'
        let(:blog) { { blog: { title: 'foo' } } }

        run_test! do |response|
          expect(response.body).to include("can't be blank")
        end
      end
    end
  end
end
```

In the above example, we see methods ```request_body_json``` ```request_body_plain``` ```request_body_xml```.
These methods can be used to describe json, plain text and xml body. They are just wrapper methods to setup posting JSON, plain text or xml into your endpoint.
The simplest most common usage is for json formatted body to use the schema: to specify the location of the schema for the request body
and the examples: :blog which will create a named example "blog" under the "requestBody / content / application/json / examples" section.
Again, documenting request response examples changed in Open API 3.0. The example above would generate a swagger.json snippet that looks like this:

```json
        ...
        {"requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "examples": {
                "blog": {  // takes the name from  examples: :blog above
                  "value": {  //this is open api 3.0 structure -> https://swagger.io/docs/specification/adding-examples/
                    "blog": { // here is the actual JSON payload that is submitted to the service, and shows up in swagger UI as an example
                      "title": "foo",
                      "content": "bar"
                    }
                  }
                }
              },
              "schema": {
                "$ref": "#/components/schemas/blog"
              }
            },
            "test/plain": {
              "schema": {
                "type": "string"
              }
            },
            "application/xml": {
              "schema": {
                "$ref": "#/components/schemas/blog"
              }
            }
          }
        },
        }
```

*NOTE:* for this example request body to work in the tests properly, you need to ``let`` a variable named *blog*.
The variable with the matching name (blog in this case) is eval-ed and captured to be placed in the examples section.
This ```let``` value is used in the integration test to run the test AND captured and injected into the requestBody section.

##### rswag response examples #####

In the same way that requestBody examples can be captured and injected into the swagger output, response examples can also be captured.
Using the above example, when the integration test is run - the swagger would include the following snippet providing more useful real world examples
capturing the response from the execution of the integration test. Again 3.0 swagger changed the structure of how these are documented.

```json
       ...  "responses": {
          "201": {
            "description": "blog created",
            "content": {
              "application/json": {
                "example": {
                  "id": 1,
                  "title": "foo",
                  "content": "bar",
                  "thumbnail": null
                },
                "schema": {
                  "$ref": "#/components/schemas/blog"
                }
              }
            }
          },
          "422": {
            "description": "invalid request",
            "content": {
              "application/json": {
                "example": {
                  "errors": {
                    "content": [
                      "can't be blank"
                    ]
                  }
                },
                "schema": {
                  "$ref": "#/components/schemas/errors_object"
                }
              }
            }
          }
        }
```
 -->
### Route Prefix for Swagger JSON Endpoints ###

The functionality to expose Swagger files, such as those generated by rswag-specs, as JSON endpoints is implemented as a Rails Engine. As with any Engine, you can change its mount prefix in _routes.rb_:

```ruby
TestApp::Application.routes.draw do
  ...

  mount Rswag::Api::Engine => 'your-custom-prefix'
end
```

Assuming a Swagger file exists at &lt;openapi_root&gt;/v1/swagger.json, this configuration would expose the file as the following JSON endpoint:

```
GET http://<hostname>/your-custom-prefix/v1/swagger.json
```

### Root Location for Swagger Files ###

You can adjust this in the _rswag_api.rb_ initializer that's installed with __rspec-api__:

```ruby
Rswag::Api.configure do |c|
  c.openapi_root = Rails.root.to_s + '/your-custom-folder-name'
  ...
end
```

__NOTE__: If you're using rswag-specs to generate Swagger files, you'll want to ensure they both use the same &lt;openapi_root&gt;. The reason for separate settings is to maintain independence between the two gems. For example, you could install rswag-api independently and create your Swagger files manually.

### Dynamic Values for Swagger JSON ##

There may be cases where you need to add dynamic values to the Swagger JSON that's returned by rswag-api. For example, you may want to provide an explicit host name. Rather than hardcoding it, you can configure a filter that's executed prior to serializing every Swagger document:

```ruby
Rswag::Api.configure do |c|
  ...

  c.swagger_filter = lambda { |swagger, env| swagger['host'] = env['HTTP_HOST'] }
end
```

Note how the filter is passed the rack env for the current request. This provides a lot of flexibility. For example, you can assign the "host" property (as shown) or you could inspect session information or an Authorization header and remove operations based on user permissions.

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

You can update the _rswag_ui.rb_ initializer, installed with rswag-ui, to specify which Swagger endpoints should be available to power the documentation UI. If you're using rswag-api, these should correspond to the Swagger endpoints it exposes. When the UI is rendered, you'll see these listed in a drop-down to the top right of the page:

```ruby
Rswag::Ui.configure do |c|
  c.openapi_endpoint '/api-docs/v1/swagger.json', 'API V1 Docs'
  c.openapi_endpoint '/api-docs/v2/swagger.json', 'API V2 Docs'
end
```

### Enable Simple Basic Auth for swagger-ui

You can also update the _rswag_ui.rb_ initializer, installed with rswag-ui to specify a username and password should you want to keep your documentation private.

```ruby
Rswag::Ui.configure do |c|
  c.basic_auth_enabled = true
  c.basic_auth_credentials 'username', 'password'
end
```

### Route Prefix for the swagger-ui ###

Similar to rswag-api, you can customize the swagger-ui path by changing its mount prefix in _routes.rb_:

```ruby
TestApp::Application.routes.draw do
  ...

  mount Rswag::Api::Engine => 'api-docs'
  mount Rswag::Ui::Engine => 'your-custom-prefix'
end
```

### Customizing the swagger-ui ###

The swagger-ui provides several options for customizing its behavior, all of which are documented here https://github.com/swagger-api/swagger-ui/tree/2.x#swaggerui. If you need to tweak these or customize the overall look and feel of your swagger-ui, then you'll need to provide your own version of index.html. You can do this with the following generator.

```ruby
rails g rswag:ui:custom

```

This will add a local version that you can modify at _app/views/rswag/ui/home/index.html.erb_. For example, it will let you to add your own `<title>` and favicon.

To replace the *"Swagger sponsored by"* brand image, you can add the following script to the generated file:

```html
<script>
  (function () {
  window.addEventListener("load", function () {
      setTimeout(function () {

          var logo = document.getElementsByClassName('link');

          logo[0].children[0].alt = "My API";
          logo[0].children[0].src = "/favicon.png";
      });
  }); })();
</script>
```

The above script would expect to find an image named `favicon.png` in the public folder.

### Serve UI Assets Directly from your Web Server

Rswag ships with an embedded version of the [swagger-ui](https://github.com/swagger-api/swagger-ui), which is a static collection of JavaScript and CSS files. These assets are served by the rswag-ui middleware. However, for optimal performance you may want to serve them directly from your web server (e.g. Apache or NGINX). To do this, you'll need to copy them to the web server root. This is the "public" folder in a typical Rails application.

```
bundle exec rake rswag:ui:copy_assets[public/api-docs]
```

__NOTE:__: The provided subfolder MUST correspond to the UI mount prefix - "api-docs" by default.


Notes to test swagger output locally with swagger editor
```
docker pull swaggerapi/swagger-editor
```
```
docker run -d -p 80:8080 swaggerapi/swagger-editor
```
This will run the swagger editor in the docker daemon and can be accessed
at ```http://localhost```. From here, you can use the UI to load the generated swagger.json to validate the output.

### Custom :getter option for parameter

To avoid conflicts with Rspec [`include`](https://github.com/rspec/rspec-rails/blob/40261bb72875c00a6e4a0ca2ac697b660d4e8d9c/spec/support/generators.rb#L18) matcher and other possible intersections like `status` method:

```
...
parameter name: :status,
          getter: :filter_status,
          in: :query,
          schema: {
            type: :string,
            enum: %w[one two three],
          }, required: false

let(:status) { nil } # will not be used in query string
let(:filter_status) { 'one' } # `&status=one` will be provided in final query
```

### Linting with RuboCop RSpec

When you lint your RSpec spec files with `rubocop-rspec`, it will fail to detect RSpec aliases that Rswag defines.
Make sure to use `rubocop-rspec` 2.0 or newer and add the following to your `.rubocop.yml`:

```yaml
inherit_gem:
  rswag-specs: .rubocop_rspec_alias_config.yml
```
