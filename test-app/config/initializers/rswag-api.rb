# frozen_string_literal: true

Rswag::Api.configure do |c|
  # Specify a root folder where OpenAPI JSON files are located
  # This is used by the OpenAPI middleware to serve requests for API descriptions
  # NOTE: If you're using rswag-specs to generate OpenAPI, you'll need to ensure
  # that it's configured to generate files in the same folder
  c.openapi_root = Rails.root.join('openapi').to_s

  # Inject a lambda function to alter the returned OpenAPI prior to serialization
  # The function will have access to the rack env for the current request
  # For example, you could leverage this to dynamically assign the "host" property
  #
  # c.openapi_filter = lambda { |openapi, env| openapi['host'] = env['HTTP_HOST'] }
end
