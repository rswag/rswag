# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'rswag'
  s.version     = ENV['RUBYGEMS_VERSION'] || '0.0.0'
  s.authors     = ['Richie Morris', 'Greg Myers', 'Jay Danielian']
  s.email       = ['domaindrivendev@gmail.com']
  s.homepage    = 'https://github.com/rswag/rswag'
  s.summary     = 'OpenAPI (formerly named Swagger) tooling for Rails APIs'
  s.description = 'Generate beautiful API documentation, including a UI to explore and test operations, directly from your rspec integration tests. OpenAPI 2 and 3 supported. More about the OpenAPI initiative here: http://spec.openapis.org/'
  s.license     = 'MIT'

  s.files = Dir['{lib}/**/*'] + [ 'MIT-LICENSE' ]

  s.add_dependency 'rswag-specs', ENV['RUBYGEMS_VERSION'] || '0.0.0'
  s.add_dependency 'rswag-api', ENV['RUBYGEMS_VERSION'] || '0.0.0'
  s.add_dependency 'rswag-ui', ENV['RUBYGEMS_VERSION'] || '0.0.0'
end
