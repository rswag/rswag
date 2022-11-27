# frozen_string_literal: true

require 'rspec/core/rake_task'

namespace :rswag do
  namespace :specs do
    desc 'Generate Swagger JSON files from integration specs'
    RSpec::Core::RakeTask.new('swaggerize') do |t|
      t.pattern = ENV.fetch(
        'PATTERN',
        'spec/requests/**/*_spec.rb, spec/api/**/*_spec.rb, spec/integration/**/*_spec.rb'
      )

      additional_rspec_opts = ENV.fetch(
        'ADDITIONAL_RSPEC_OPTS',
        ''
      )

      t.rspec_opts = [additional_rspec_opts]

      if Rswag::Specs::RSPEC_VERSION > 2 && Rswag::Specs.config.swagger_dry_run
        t.rspec_opts += ['--format Rswag::Specs::SwaggerFormatter', '--dry-run', '--order defined']
      else
        ActiveSupport::Deprecation.warn('Rswag::Specs: WARNING: Support for RSpec 2.X will be dropped in v3.0')
        t.rspec_opts += ['--format Rswag::Specs::SwaggerFormatter', '--order defined']
      end
    end
  end
end

task rswag: ['rswag:specs:swaggerize']
