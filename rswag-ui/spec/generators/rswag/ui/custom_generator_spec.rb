# frozen_string_literal: true

require 'generator_spec'
require 'generators/rswag/ui/custom/custom_generator'

module Rswag
  module Ui
    describe CustomGenerator do
      include GeneratorSpec::TestCase
      destination File.expand_path('tmp', __dir__)

      it 'creates a local version of index.html.erb' do
        prepare_destination
        run_generator
        assert_file('app/views/rswag/ui/home/index.html.erb')
      end
    end
  end
end
