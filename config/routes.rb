SwaggerRails::Engine.routes.draw do
  get '/index.html', to: 'swagger_ui#index', as: :swagger_ui
  get '/:api_version/swagger.json', to: 'swagger_docs#show', as: :swagger
end
