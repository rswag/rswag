SwaggerRails.configure do |c|

  # List the names and paths (relative to config/swagger) of Swagger
  # documents you'd like to expose in your swagger-ui
  c.swagger_docs = {
    'API V1' => 'v1/swagger.json'
  }
end
