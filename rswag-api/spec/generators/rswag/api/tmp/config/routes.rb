TestApp::Application.routes.draw do
  mount Rswag::Api::Engine => '/api-docs'

end
