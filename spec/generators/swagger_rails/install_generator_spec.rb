require 'rails_helper'
require 'generators/swagger_rails/install/install_generator'

module SwaggerRails

  describe InstallGenerator do
    include GeneratorSpec::TestCase
    destination File.expand_path('../tmp', __FILE__)

    before(:all) do
      prepare_destination
      fixtures_dir = File.expand_path('../fixtures', __FILE__)
      FileUtils.cp_r("#{fixtures_dir}/config", destination_root)
      FileUtils.cp_r("#{fixtures_dir}/spec", destination_root)

      run_generator
    end

    it 'creates a default swagger directory' do
      assert_directory('swagger/v1')
    end

    it 'installs swagger_rails initializer' do
      assert_file('config/initializers/swagger_rails.rb')
    end

    it 'installs the swagger_helper for rspec' do
      assert_file('spec/swagger_helper.rb')
    end

    it 'wires up the swagger routes'
    # Not sure how to test this
  end
end
