SwaggerRails.configure do |c|

  # List the names and paths of Swagger
  # documents you'd like to expose in your swagger-ui
  c.swagger_docs = {
    'API V1' => '/swagger/v1/swagger.json',
    'API V2' => '/swagger/v2/swagger.json'
  }
end
