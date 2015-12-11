module SwaggerRails
  class SwaggerUiController < ApplicationController

    def index
      @discovery_path = swagger_path(SwaggerRails.target_api_version)
      render :index, layout: false
    end
  end
end
