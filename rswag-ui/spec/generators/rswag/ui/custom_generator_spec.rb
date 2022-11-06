# frozen_string_literal: true

require 'generator_spec'
require 'generators/rswag/ui/custom/custom_generator'

RSpec.describe Rswag::Ui::CustomGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path('tmp', __dir__)

  before(:all) do
    prepare_destination
    run_generator
  end

  it 'creates a local version of index.html.erb' do
    assert_file('app/views/rswag/ui/home/index.html.erb')
  end
end
