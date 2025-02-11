# frozen_string_literal: true

require 'generator_spec'
require 'generators/rswag/install/install_generator'

module Rswag
  module Specs
    describe InstallGenerator do
      include GeneratorSpec::TestCase
      destination File.expand_path('tmp', __dir__)

      it 'installs the necessary files' do
        prepare_destination
        fixtures_dir = File.expand_path('fixtures', __dir__)
        FileUtils.cp_r("#{fixtures_dir}/config", destination_root)
        FileUtils.cp_r("#{fixtures_dir}/spec", destination_root)

        run_generator

        assert_file('spec/openapi_helper.rb')
        assert_file('config/rswag_api.rb')
        assert_file('config/rswag_ui.rb')
      end
    end
  end
end
