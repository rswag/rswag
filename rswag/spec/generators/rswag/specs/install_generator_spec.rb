# frozen_string_literal: true

require 'generator_spec'
require 'generators/rswag/install/install_generator'

module Rswag
  module Specs

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

      it 'installs spec helper rswag-specs' do
        assert_file('spec/swagger_helper.rb')
      end

      it 'installs initializer for rswag-api' do
        assert_file('config/rswag_api.rb')
      end

      it 'installs initializer for rswag-ui' do
        assert_file('config/rswag_ui.rb')
      end
    end
  end
end
