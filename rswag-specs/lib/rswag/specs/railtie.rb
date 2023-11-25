# frozen_string_literal: true

module Rswag
  module Specs
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load File.expand_path('../../tasks/rswag-specs_tasks.rake', __dir__)
      end

      generators do
        require 'generators/rspec/swagger_generator'
      end

      initializer 'rswag-specs.deprecator' do |app|
        if app.respond_to?(:deprecators)
          app.deprecators[:rswag_specs] = Rswag::Specs.deprecator
        end
      end
    end
  end
end
