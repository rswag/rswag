$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'rswag/api/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rswag-api"
  s.version     = Rswag::Api::VERSION
  s.authors     = ["Richie Morris"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/rswag"
  s.summary     = "A Rails Engine that exposes Swagger files as JSON endpoints"
  s.description = "Open up your API to the phenomenal Swagger ecosystem by exposing Swagger files, that describe your service, as JSON endpoints"
  s.license     = "MIT"

  s.files = Dir["{lib}/**/*"] + ["MIT-LICENSE", "Rakefile"]

  s.add_dependency "rails", ">= 3.1", "< 5.2"
end
