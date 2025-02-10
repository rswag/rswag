Rswag::Ui.configure do |c|

  # List the OpenAPI endpoints that you want to be documented through the swagger-ui
  # The first parameter is the path (absolute or relative to the UI host) to the corresponding
  # JSON endpoint and the second is a title that will be displayed in the document selector
  # NOTE: If you're using rspec-api to expose OpenAPI files (under openapi_root) as JSON endpoints,
  # then the list below should correspond to the relative paths for those endpoints

  c.openapi_endpoint '/api-docs/v1/openapi.json', 'API V1 Docs'
end
