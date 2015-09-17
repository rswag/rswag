SwaggerRails::Engine.routes.draw do

  get '/ui', to: 'swagger_ui#show'
  get '/:api_version/swagger.json', to: 'swagger_docs#show', as: :swagger
end
