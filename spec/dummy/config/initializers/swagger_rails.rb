SwaggerRails.configure do |c|

  # Specify a root folder where Swagger JSON files are located
  # This is used by the Swagger middleware to serve requests for API descriptions
  # NOTE: If you're using the rspec DSL to generate Swagger, you'll need to ensure
  # that the same folder is also specified in spec/swagger_helper.rb
  c.swagger_root = Rails.root.to_s + '/swagger'

  # Inject a lamda function to alter the returned Swagger prior to serialization
  # The function will have access to the rack env for the current request
  # For example, you could leverage this to dynamically assign the "host" property
  #
  #c.swagger_filter = lambda { |swagger, env| swagger['host'] = env['HTTP_HOST'] }
end
