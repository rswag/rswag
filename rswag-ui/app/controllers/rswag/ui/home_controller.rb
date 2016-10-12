module Rswag
  module Ui
    class HomeController < ActionController::Base

      def index
        @swagger_endpoints = Rswag::Ui.config.swagger_endpoints
        render :index, layout: false
      end
    end
  end
end
