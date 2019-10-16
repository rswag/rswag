class AuthTestsController < ApplicationController

  # POST /auth-tests/basic
  def basic
    return head :unauthorized unless authenticate_basic
    head :no_content
  end

  # POST /auth-tests/api-key
  def api_key
    return head :unauthorized unless authenticate_api_key
    head :no_content
  end

  # POST /auth-tests/basic-and-api-key
  def basic_and_api_key
    return head :unauthorized unless authenticate_basic and authenticate_api_key
    head :no_content
  end

  private

  def authenticate_basic
    authenticate_with_http_basic { |u, p| u == 'jsmith' && p == 'jspass' }
  end

  def authenticate_api_key
    params['api_key'] == 'foobar'
  end
end
