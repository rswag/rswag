SwaggerRails.configure do |c|

  # Define your swagger documents and provide global metadata
  # Describe actual operations in your spec/test files
  c.swagger_doc 'v1/swagger.json' do
    {
      info: {
        title: 'API V1',
        version: 'v1'
      }
    }
  end
end
