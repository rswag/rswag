# frozen_string_literal: true

require 'rspec/core/rake_task'

namespace :rswag do
  namespace :specs do
    desc 'Generate OpenAPI JSON files from integration specs'
    RSpec::Core::RakeTask.new('swaggerize') do |t|
      t.pattern = ENV.fetch(
        'PATTERN',
        'spec/requests/**/*_spec.rb, spec/api/**/*_spec.rb, spec/integration/**/*_spec.rb'
      )

      additional_rspec_opts = ENV.fetch(
        'ADDITIONAL_RSPEC_OPTS',
        ''
      )

      t.rspec_opts = [
        '--format Rswag::Specs::OpenapiFormatter',
        '--order defined'
      ] << additional_rspec_opts

      if Rswag::Specs.config.rswag_dry_run
        t.rspec_opts += ['--dry-run']
      end
    end
  end
end

task rswag: ['rswag:specs:swaggerize']
