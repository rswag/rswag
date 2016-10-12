TestApp::Application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'

  mount Rswag::Api::Engine => '/api-docs'

  resources :blogs, defaults: { :format => :json }

  mount Rswag::Api::Engine => 'api-docs'
  mount Rswag::Ui::Engine => 'api-docs'
end
