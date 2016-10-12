TestApp::Application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'

end
