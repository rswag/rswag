module SwaggerRails
  class SwaggerDocsController < ApplicationController

    def show
      render json: swagger_json_for(params[:api_version]), layout: false
    end

    private

    def swagger_json_for(api_version)
      path = File.join(Rails.root, 'config', 'swagger', api_version, 'swagger.json')
      File.read(path)
    end
  end
end
