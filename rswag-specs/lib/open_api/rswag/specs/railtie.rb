# frozen_string_literal: true

module OpenApi
  module Rswag
    module Specs
      class Railtie < ::Rails::Railtie
        rake_tasks do
          load File.expand_path('../../../tasks/rswag-specs_tasks.rake', __dir__)
        end
      end
    end
  end
end
