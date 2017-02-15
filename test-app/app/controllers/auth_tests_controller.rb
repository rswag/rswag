class AuthTestsController < ApplicationController
  wrap_parameters Blog
  respond_to :json

  # POST /auth-tests/basic
  def basic
    if authenticate_with_http_basic { |u, p| u == 'jsmith' && p == 'jspass' }
      head :no_content
    else
      request_http_basic_authentication
    end
  end
end
