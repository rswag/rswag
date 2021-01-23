# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'rswag-specs'
  s.version     = ENV['TRAVIS_TAG'] || '0.0.0'
  s.authors     = ['Richie Morris', 'Greg Myers', 'Jay Danielian']
  s.email       = ['domaindrivendev@gmail.com']
  s.homepage    = 'https://github.com/rswag/rswag'
  s.summary     = 'An OpenAPI-based (formerly called Swagger) DSL for rspec-rails & accompanying rake task for generating OpenAPI specification files'
  s.description = 'Simplify API integration testing with a succinct rspec DSL and generate OpenAPI specification files directly from your rspecs. More about the OpenAPI initiative here: http://spec.openapis.org/'
  s.license     = 'MIT'

  s.files = Dir['{lib}/**/*'] + ['MIT-LICENSE', 'Rakefile']

  s.add_dependency 'activesupport', '>= 3.1', '< 7.0'
  s.add_dependency 'railties', '>= 3.1', '< 7.0'
  s.add_dependency 'json-schema', '~> 2.2'
end
