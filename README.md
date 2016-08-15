swagger_rails
=========

Generate API documentation, including a slick discovery UI and playground, directly from your rspec integration specs. Use the provided DSL to describe and test API operations in your spec files. Then, you can easily generate corresponding swagger.json files and serve them up with an embedded version of [swagger-ui](https://github.com/swagger-api/swagger-ui). Best of all, it requires minimal coding and maintenance, allowing you to focus on building an awesome API!

And that's not all ...

Once you have a Web API that can describe itself in Swagger, you've opened the treasure chest of Swagger-based tools including a client generator that can be targeted to a wide range of popular platforms. See [swagger-codegen](https://github.com/swagger-api/swagger-codegen) for more details.

__NOTE__: It's early days so please be gentle when reporting issues :) As author of a similar project in the .NET space - [Swashbuckle](https://github.com/domaindrivendev/Swashbuckle), that's become very popular, I think there's real potential here. Please feel free to contribute. I'll be more than happy to consider PR's ... so long as they include tests.

## Getting Started ##

1. Add this line to your applications _Gemfile_:

    ```ruby
    gem swagger_rails
    ```

2. Run the install generator

    ```ruby
    rails g swagger_rails:install
    ```

3. Create an integration spec to describe and test your API

    ```ruby
    require 'swagger_helper'

    describe 'Blogs API' do

      path '/blogs' do

        post 'creates a new blog' do
          consumes 'application/json'
          operation_description 'Detailed implementation notes for the create a new blog API endpoint'
          parameter :blog, in: :body, schema: {
            type: :object,
            properties: {
              title: { :type => :string },
              content: { :type => :string }
            },
            required: [ 'title', 'content' ]
          }

          response '200', 'success' do
            let(:blog) { { title: 'foo', content: 'bar' } }
            run_test!
          end

          response '422', 'invalid request' do
            let(:blog) { { title: 'foo' } }
            run_test!
          end
        end
      end
    end
    ```

4. Generate the swagger.json file(s)

    ```ruby
    rake swaggerize
    ```

5. Spin up your app and check out the awesome, auto-generated docs at _/api-docs_!

## How does it Work? ##

There's two separate parts to swagger rails:

1. Tooling to easily generate swagger descriptions directly from your API tests/specs  
2. Rails middleware to auto-magically serve a swagger-ui that's powered by those descriptions

The tooling is designed to fit seamlessly into your development workflow, with the swagger docs and UI being a by-product that you get for free ... well almost free :) You'll need to use the provided rspec DSL. But, it's an intuitive syntax (based on the [swagger-spec](http://swagger.io/specification/)) and, IMO, a very succint and expressive way to write api/integration tests.

Once you've generated the swagger files, the functionality to serve them up, along with the swagger-ui, is provided as a Rails Engine. After running the install generator, you'll see the following line added to _routes.rb_

  ```ruby
  mount SwaggerRails::Engine => '/api-docs'
  ```
  
This will wire up routes for the swagger docs and swagger-ui assets, all prefixed with "/api-docs". For example, if you navigate to "/api-docs/index.html" you'll get the swagger-ui. If you navigate to "/api-docs/v1/swagger.json", you'll get the swagger.json file under your app root at "swagger/v1/swagger.json" - assuming it was generated.

If you'd like your swagger resources to appear under a different base path, you can change the Engine mount point from "/api-docs" to something else.

## Multiple Swagger Documents ##

By default, the generator will create all operation descriptions in a single swagger.json file. You can customize this by defining additional documents in the swagger_helper (installed under your spec folder) ...

  ```ruby
  RSpec.configure do |config|
    ...

    config.swagger_docs = {
      'v1/swagger.json' => {
        swagger: '2.0',
        info: {
          title: 'API V1',
          version: 'v1'
        }
      },

      'v2/swagger.json' => {
        swagger: '2.0',
        info: {
          title: 'API V2',
          version: 'v2'
        }
      }
    }
  end
  ```

And then tagging your spec's with the target swagger_doc:

  ```ruby
  require 'swagger_helper'

  describe 'Blogs API V2', swagger_doc: 'v2/swagger.json' do

      path '/blogs' do
        ...
      end
    end
  end
  ```

Then, when you run the generator and spin up the swagger-ui, you'll see a select box in the top right allowing your audience to switch between the different API versions.

## Tweaking the Swagger Document with Request Context ##

You can provide global metadata for Swagger documents in the swagger_helper file and this will be included in the resulting Swagger JSON when you run the "swaggerize" rake task. For the most part, this is sufficient. However, you may want to make some changes that require the current request context. This is possible by applying an optional swagger_filter in the swagger_rails initializer (installed into config/initializers):

  ```ruby
  SwaggerRails.configure do |c|
    ...

    c.swagger_filter = lambda { |swagger, env| swagger['host'] = env['HTTP_HOST'] }
  end
  ```

This function will get called prior to serialization of any Swagger file and is passed the rack env for the current request. This provides a lot of flexibilty. For example, you could dynamically assign the "host" property (as shown above) or you could inspect session information or Authoriation header and remove operations based on user permissions.

## Customizing the UI ##

The swagger-ui provides several options for customizing it's behavior, all of which are documented here https://github.com/swagger-api/swagger-ui#swaggerui. If you need to tweak these or customize the overall look and feel of your swagger-ui, then you'll need to provide your own version of index.html. You can do this with the following generator.

```ruby
rails g swagger_rails:custom_ui
```

This will add a local version that you can customize at "app/views/swagger_rails/swagger_ui/index.html.erb"
