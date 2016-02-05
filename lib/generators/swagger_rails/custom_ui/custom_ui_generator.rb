module SwaggerRails
  class CustomUiGenerator < Rails::Generators::Base
    source_root File.expand_path('../files', __FILE__)

    def add_custom_index
      copy_file('index.html.erb', 'app/views/swagger_rails/swagger_ui/index.html.erb')
    end
  end
end
