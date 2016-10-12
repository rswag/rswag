require 'ostruct'

module Rswag
  module Ui
    class Configuration
      attr_reader :swagger_endpoints

      def initialize
        @swagger_endpoints = []
      end

      def swagger_endpoint(path, title)
        @swagger_endpoints << OpenStruct.new(path: path, title: title)
      end
    end
  end
end
