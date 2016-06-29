require 'json'

module SwaggerRails
  class SwaggerUiController < ApplicationController

    def root
      redirect_to action: 'index'
    end

    def index
      swagger_root = SwaggerRails.config.resolve_swagger_root(request.env)
      swagger_filenames = Dir["#{swagger_root}/**/*.json"]

      @discovery_paths = Hash[
        swagger_filenames.map do |filename|
          [
            "#{root_path.chomp('/')}#{filename.sub(swagger_root, '')}",
            load_json(filename)["info"]["title"]
          ]
        end
      ]

      render :index, layout: false
    end

    private

    def load_json(filename)
      JSON.parse(File.read(filename))
    end
  end
end
