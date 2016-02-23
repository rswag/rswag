Rails.application.routes.draw do
  resources :blogs, defaults: { :format => :json }

  mount SwaggerRails::Engine => '/api-docs'
end
