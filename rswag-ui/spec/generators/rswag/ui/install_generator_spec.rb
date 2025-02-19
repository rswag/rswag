# frozen_string_literal: true

require 'generator_spec'
require 'generators/rswag/ui/install/install_generator'

module Rswag
  module Ui
    describe InstallGenerator do
      include GeneratorSpec::TestCase
      destination File.expand_path('tmp', __dir__)

      it 'installs the Rails initializer' do
        prepare_destination
        fixtures_dir = File.expand_path('fixtures', __dir__)
        FileUtils.cp_r("#{fixtures_dir}/config", destination_root)

        run_generator

        assert_file('config/initializers/rswag_ui.rb')
      end

      # Don't know how to test this
      # it 'wires up routes'
    end
  end
end
