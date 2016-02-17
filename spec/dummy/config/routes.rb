Rails.application.routes.draw do
  mount SwaggerRails::Engine => '/api-docs'

  resources :blogs, only: [ :create, :index, :show ]
end
