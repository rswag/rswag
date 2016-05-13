SwaggerRails.configure do |c|

  # Define your swagger documents and provide any global metadata here
  # (Individual operations are generated from your spec/test files)
  c.swagger_doc 'v1/swagger.json',
    {
      swagger: '2.0',
      info: {
        title: 'API V1',
        version: 'v1'
      }
    }

  # Specify a location to output generated swagger files
  c.swagger_dir File.expand_path('../../../swagger', __FILE__)
end
