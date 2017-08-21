TestApp::Application.routes.draw do
  resources :blogs
  put '/blogs/:id/upload', to: 'blogs#upload'

  post 'auth-tests/basic', to: 'auth_tests#basic'
  post 'auth-tests/api-key', to: 'auth_tests#api_key'
  post 'auth-tests/basic-and-api-key', to: 'auth_tests#basic_and_api_key'

  mount Rswag::Api::Engine => 'api-docs'
  mount Rswag::Ui::Engine => 'api-docs'
end
