module SwaggerRails
  class SwaggerUiController < ApplicationController

    def index
      @discovery_paths = Hash[
        SwaggerRails.config.swagger_docs.map do |path, doc|
          [ "#{root_path}#{path}", doc[:info][:title] ]
        end
      ]

      render :index, layout: false
    end
  end
end
