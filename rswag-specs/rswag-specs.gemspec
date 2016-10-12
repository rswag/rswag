$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'rswag/specs/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rswag-specs"
  s.version     = Rswag::Specs::VERSION
  s.authors     = ["Richie Morris"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/rswag"
  s.summary     = "A Swagger-based DSL for rspec-rails & accompanying rake task for generating Swagger files"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile" ]

  s.add_dependency "rails", ">= 3.1", "< 5.1" 
  s.add_dependency 'json-schema'
  s.add_development_dependency 'rspec-rails'
end
