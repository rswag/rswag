SwaggerRails::Engine.routes.draw do

  get '/ui', to: 'swagger_ui#show'
  get '/docs/:api_version', to: 'swagger_docs#show'
end
