SwaggerRails.configure do |c|

  # Define the swagger documents you'd like to expose and provide global metadata
  c.swagger_doc 'v1/swagger.json' do
    {
      info: {
        title: 'API V1',
        version: 'v1'
      }
    }
  end
end
