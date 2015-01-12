$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "swagger_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "swagger_rails"
  s.version     = SwaggerRails::VERSION
  s.authors     = ["domaindrivendev"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of SwaggerRails."
  s.description = "TODO: Description of SwaggerRails."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.0"
end
