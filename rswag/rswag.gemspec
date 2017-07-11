$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rswag"
  s.version     = ENV['TRAVIS_TAG'] || '0.0.0'
  s.authors     = ["Richie Morris"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/rswag"
  s.summary     = "Swagger tooling for Rails API's"
  s.description = "Generate beautiful API documentation, including a UI to explore and test operations, directly from your rspec integration tests"
  s.license     = "MIT"

  s.files = Dir["{lib}/**/*"] + [ "MIT-LICENSE" ]

  s.add_dependency 'rswag-specs', ENV['TRAVIS_TAG'] || '0.0.0'
  s.add_dependency 'rswag-api', ENV['TRAVIS_TAG'] || '0.0.0'
  s.add_dependency 'rswag-ui', ENV['TRAVIS_TAG'] || '0.0.0'
end
