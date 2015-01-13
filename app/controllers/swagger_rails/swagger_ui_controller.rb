module SwaggerRails
  class SwaggerUiController < ApplicationController

    def show
      @discovery_url = request.path.gsub('/ui', '/docs/v1')
    end
  end
end
