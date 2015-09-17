module SwaggerRails
  class SwaggerUiController < ApplicationController

    def show
      @discovery_path = swagger_path('v1')
      render :index
    end
  end
end
