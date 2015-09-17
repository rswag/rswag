Rails.application.routes.draw do

  mount SwaggerRails::Engine => '/swagger'
end
