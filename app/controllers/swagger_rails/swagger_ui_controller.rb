require 'json'

module SwaggerRails
  class SwaggerUiController < ApplicationController

    def root
      redirect_to action: 'index'
    end

    def index
      swagger_root = SwaggerRails.config.resolve_swagger_root(request.env)
      swagger_root.concat('/') unless swagger_root.end_with?('/')

      swagger_filenames = Dir["#{swagger_root}/**/*.json"]

      @discovery_paths = Hash[
        swagger_filenames.map do |filename|
          [
            filename.sub(swagger_root, root_path.chomp('/')),
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
