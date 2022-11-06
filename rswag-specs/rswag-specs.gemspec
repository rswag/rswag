# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'rswag-specs'
  s.version     = ENV['RUBYGEMS_VERSION'] || '0.0.0'
  s.authors     = ['Richie Morris', 'Greg Myers', 'Jay Danielian']
  s.email       = ['domaindrivendev@gmail.com']
  s.homepage    = 'https://github.com/rswag/rswag'
  s.license     = 'MIT'
  s.files       = Dir['{lib}/**/*'] + %w[MIT-LICENSE Rakefile]
  s.summary     = <<~SUMMARY.squish
    An OpenAPI-based (formerly called Swagger) DSL for rspec-rails &
    accompanying rake task for generating OpenAPI specification files
  SUMMARY
  s.description = <<~DESCRIPTION.squish
    Simplify API integration testing with a succinct rspec DSL and generate
    OpenAPI specification files directly from your rspec tests. More about
    the OpenAPI initiative here: http://spec.openapis.org/'
  DESCRIPTION
  s.required_ruby_version = '>= 2.7'

  s.add_dependency 'activesupport', '>= 3.1', '< 7.1'
  s.add_dependency 'json-schema', '>= 2.2', '< 4.0'
  s.add_dependency 'railties', '>= 3.1', '< 7.1'
  s.add_dependency 'rspec-core', '>=2.14'

  s.add_development_dependency 'simplecov', '=0.21.2'
end
