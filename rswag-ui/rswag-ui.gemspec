# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'rswag-ui'
  s.version     = ENV['RUBYGEMS_VERSION'] || '0.0.0'
  s.authors     = ['Richie Morris', 'Greg Myers', 'Jay Danielian']
  s.email       = ['domaindrivendev@gmail.com']
  s.homepage    = 'https://github.com/rswag/rswag'
  s.summary     = 'A Rails Engine that includes swagger-ui and powers it from configured OpenAPI (formerly named Swagger) endpoints'
  s.description = 'Expose beautiful API documentation, powered by Swagger JSON endpoints, including a UI to explore and test operations. More about the OpenAPI initiative here: http://spec.openapis.org/'
  s.license     = 'MIT'

  s.files = Dir.glob('{lib,node_modules}/**/*') + ['MIT-LICENSE', 'Rakefile' ]

  s.add_dependency 'actionpack', '>=3.1', '< 7.1'
  s.add_dependency 'railties', '>= 3.1', '< 7.1'

  s.add_development_dependency 'simplecov', '=0.21.2'
end
