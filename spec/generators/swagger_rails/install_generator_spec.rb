require 'rails_helper'
require 'generators/swagger_rails/install/install_generator'

describe SwaggerRails::InstallGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path('../tmp', __FILE__)

  before(:all) do
    prepare_destination
    config_dir = File.expand_path('../../fixtures/config', __FILE__)
    FileUtils.cp_r(config_dir, destination_root)

    run_generator
  end

  it 'creates a default swagger.json file' do
    assert_file('config/swagger/v1/swagger.json')
  end

  it 'creates a swagger_rails initializer' do
    assert_file('config/initializers/swagger_rails.rb')
  end

  it 'wires up the swagger routes' do
    pending('not sure how to test this')
    this_should_not_get_executed
  end
end
