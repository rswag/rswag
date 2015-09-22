module SwaggerRails
  class SwaggerUiController < ApplicationController

    def index
      @discovery_path = swagger_path('v1')
      render :index, layout: false
    end
  end
end
