TestApp::Application.routes.draw do
  resources :blogs
  put '/blogs/:id/upload', to: 'blogs#upload'

  post 'auth-tests/basic', to: 'auth_tests#basic'

  mount Rswag::Api::Engine => 'api-docs'
  mount Rswag::Ui::Engine => 'api-docs'
end
