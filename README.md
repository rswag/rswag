swagger-rails
=========

Seamlessly adds a [Swagger](http://swagger.io/) to Rails-based API's! You create one or more swagger.json files to describe your API and swagger-rails will serve it up along with an embedded version of the [swagger-ui](https://github.com/swagger-api/swagger-ui). This means you can complement your API with a slick discovery UI to assist consumers with their integration efforts. Best of all, it requires minimal coding and maintenance, allowing you to focus on building an awesome API!

And that's not all ...

Once you have a Web API that can describe itself in Swagger, you've opened the treasure chest of Swagger-based tools including a client generator that can be targeted to a wide range of popular platforms. See [swagger-codegen](https://github.com/swagger-api/swagger-codegen) for more details.

## Getting Started ##

1. Add this line to your applications _Gemfile_:

    ```ruby
    gem swagger_rails
    ```

2. Run the install generator

    ```ruby
    rails g swagger_rails:install
    ```

3. Spin up your app and navigate to '/api-docs'

    _This is where your awesome API docs and playground can be viewed_

4. Update the sample swagger.json (under config/swagger/v1)  to describe your API

  _Swagger is a well thought-out and intuitive format so referring to samples will help in getting started. For some of the finer details, you shoud refer to the spec_

    * _The Demo JSON: http://petstore.swagger.io/v2/swagger.json_
    * _The Demo UI: http://petstore.swagger.io/_
    * _The Spec.: http://swagger.io/specification/_

## How does it Work? ##

The install generator will add the following entry to your applications _routes.rb_

  ```ruby
  mount SwaggerRails::Engine => '/api-docs'
  ```
  
This will wire up routes for the swagger-ui assets and the raw JSON descriptions, all prefixed with "/api-docs". For example, if you navigate to "/api-docs/index.html" you'll get the swagger-ui. If you navigate to "/api-docs/v1/swagger.json", you'll get the sample swagger.json that's installed into your app directory at "config/swagger/v1/swagger.json".

If you'd like your Swagger resources to appear under a different base path, you can change the Engine mount point from "/api-docs" to something else.

By default, the swagger-ui will request a service description at "&lt;mount-point&gt;/v1/swagger.json" and then use that to generate the slick documentation and playground UI. If you'd like to change the path to your JSON descriptions or create multiple descriptions, you can change the folder structure and files under "config/swagger". For example, you could describe different versions of your API as follows

  ```
  |-- app
  |-- config
    |-- swagger
      |-- v1
        |-- swagger.json
      |-- v2
        |-- swagger.json
      |-- v3
        |-- swagger.json
  ```

This will expose each of those descriptions as JSON endpoints. Next, you'll need to tell swagger-ui which of these endpoints you want to provide documentation for. This can be configured in the initializer that's installed at "config/initializers/swagger_rails":

  ```ruby
  SwaggerRails.configure do |c|

  c.swagger_docs = {
    'API V1' => 'v1/swagger.json',
    'API V2' => 'v2/swagger.json',
    'API V3' => 'v3/swagger.json'
  }
  end
  ```

Now, if you view the swagger-ui, you'll notice that each of these are available in the select box at the top right of the page, allowing users to easily navigate between different versions of your API.

## Customizing the UI ##

The swagger-ui provides several options for customizing it's behavior, all of which are documented here https://github.com/swagger-api/swagger-ui#swaggerui. If you need to tweak these or customize the overall look and feel of your swagger-ui, then you'll need to provide your own version of index.html. You can do this with the following generator.

```ruby
rails g swagger_rails:custom_ui
```

This will add a local version that you can customize at "app/views/swagger_rails/swagger_ui/index.html.erb"
