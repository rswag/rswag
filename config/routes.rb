SwaggerRails::Engine.routes.draw do
  root to: 'swagger_ui#root'
  get '/index.html', to: 'swagger_ui#index'
end
