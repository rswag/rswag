require 'rails/generators'

module Rswag
  module Ui
    class CustomGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../../../../lib/rswag/ui', __FILE__)

      def add_custom_index
        copy_file('index.erb', 'app/views/rswag/ui/home/index.html.erb')
      end
    end
  end
end
