SwaggerRails::Engine.routes.draw do
  root to: 'application#redirect_to_swagger_ui'
  get '/index.html', to: 'swagger_ui#index', as: :swagger_ui
end
