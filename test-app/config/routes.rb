TestApp::Application.routes.draw do
  resources :blogs, defaults: { :format => :json }
  put '/blogs/:id/upload', to: 'blogs#upload'

  mount Rswag::Api::Engine => 'api-docs'
  mount Rswag::Ui::Engine => 'api-docs'
end
