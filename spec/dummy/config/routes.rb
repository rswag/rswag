Rails.application.routes.draw do

  mount SwaggerRails::Engine => "/swagger_rails"
end
