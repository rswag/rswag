# desc "Explaining what the task does"
# task :swagger_rails do
#   # Task goes here
# end

if defined?(RSpec)
  require 'rspec/core/rake_task'

  desc 'Generate Swagger JSON files from integration specs'
  RSpec::Core::RakeTask.new('swaggerize') do |t|
    t.pattern = 'spec/requests/**/*_spec.rb, spec/api/**/*_spec.rb, spec/integration/**/*_spec.rb'
    t.rspec_opts = [ '--format SwaggerRails::RSpec::Formatter', '--dry-run' ]
  end
end
