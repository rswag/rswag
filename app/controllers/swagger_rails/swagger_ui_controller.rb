module SwaggerRails
  class SwaggerUiController < ApplicationController

    def index
      @discovery_paths = Hash[
        SwaggerRails.swagger_docs.map do |name, path|
          [ name, "#{root_path}#{path}" ]
        end
      ]

      render :index, layout: false
    end
  end
end
