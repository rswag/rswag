Rails.application.routes.draw do
  mount SwaggerRails::Engine => '/api-docs'

end
