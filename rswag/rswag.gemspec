$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'rswag/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rswag"
  s.version     = Rswag::VERSION
  s.authors     = ["Richie Morris"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/rswag"
  s.summary     = "Swagger tooling for Rails API's"
  s.description = "Generate beautiful API documentation, including a UI to explore and test operations, directly from your rspec integration tests"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*"] + [ "MIT-LICENSE" ]

  s.add_dependency 'rswag-specs', Rswag::VERSION
  s.add_dependency 'rswag-api', Rswag::VERSION
  s.add_dependency 'rswag-ui', Rswag::VERSION
end
