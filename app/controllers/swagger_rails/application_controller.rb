module SwaggerRails
  class ApplicationController < ActionController::Base

    def redirect_to_swagger_ui
      redirect_to swagger_ui_path
    end
  end
end
