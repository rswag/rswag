require 'rails_helper'
require 'generators/swagger_rails/custom_ui/custom_ui_generator'

module SwaggerRails

  describe CustomUiGenerator do
    include GeneratorSpec::TestCase
    destination File.expand_path('../tmp', __FILE__)

    before(:all) do
      prepare_destination
      run_generator
    end

    it 'creates a local version of index.html.erb' do
      assert_file('app/views/swagger_rails/swagger_ui/index.html.erb')
    end
  end
end
