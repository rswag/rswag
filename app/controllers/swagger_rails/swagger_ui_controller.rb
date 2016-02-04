module SwaggerRails
  class SwaggerUiController < ApplicationController

    def index
      render :index, layout: false
    end
  end
end
