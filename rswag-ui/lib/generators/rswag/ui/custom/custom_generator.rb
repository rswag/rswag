require 'rails/generators'

module Rswag
  module Ui
    class CustomGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../../../../app/views/rswag/ui/home', __FILE__)

      def add_custom_index
        copy_file('index.html.erb', 'app/views/rswag/ui/home/index.html.erb')
      end
    end
  end
end
