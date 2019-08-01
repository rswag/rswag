TestApp::Application.routes.draw do
  resources :blogs, defaults: { :format => :json }

  mount Rswag::Api::Engine => 'api-docs'
  mount Rswag::Ui::Engine => 'api-docs'
end
