SwaggerRails::Engine.routes.draw do
  get '/index.html', to: 'swagger_ui#index', as: :swagger_ui
end
