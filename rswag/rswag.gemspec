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
  s.description = "Generate Swagger files direclty from integration specs, expose them as JSON endpoints, and use them to power a slick API docs and discovery UI"

  s.files = Dir["{app,config,db,lib}/**/*"] + [ "MIT-LICENSE" ]

  s.add_dependency 'rswag-specs'
  s.add_dependency 'rswag-api'
  s.add_dependency 'rswag-ui'
end
