require 'rack/auth/basic'

class BasicAuth < ::Rack::Auth::Basic
  def call(env)
    return @app.call(env) unless env_matching_path

    super(env)
  end

  private

  def env_matching_path
    swagger_endpoints = Rswag::Ui.config.swagger_endpoints[:urls]
    swagger_endpoints.find do |endpoint|
      base_path = base_path(endpoint[:url])
      env_base_path = base_path(env['PATH_INFO'])

      base_path == env_base_path
    end
  end

  def base_path(url)
    url.downcase.split('/')[1]
  end
end
