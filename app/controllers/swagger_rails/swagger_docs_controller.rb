module SwaggerRails
  class SwaggerDocsController < ApplicationController

    def show
      render file: swagger_file_path_for(params[:api_version]), layout: false
    end

    private

    def swagger_file_path_for(api_version)
      File.join(Rails.root, 'config', 'swagger', api_version, 'swagger.json')
    end
  end
end
