require 'rails_helper'
require 'generators/swagger_rails/install/install_generator'

describe SwaggerRails::InstallGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path('../tmp', __FILE__)

  before(:all) do
    prepare_destination
    run_generator
  end

  it 'creates a default swagger.json file' do
    assert_file('config/swagger/v1/swagger.json')
  end

  it 'creates a swagger_rails initializer' do
    assert_file('config/initializers/swagger_rails.rb')
  end
end
