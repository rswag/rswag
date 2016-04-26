$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "swagger_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "swagger_rails"
  s.version     = SwaggerRails::VERSION
  s.authors     = ["domaindrivendev"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/swagger-rails"
  s.summary     = "Seamlessly adds a Swagger to Rails-based API's"
  s.description = "Seamlessly adds a Swagger to Rails-based API's"
  s.license     = "MIT"

  s.files = Dir["{app,bower_components/swagger-ui/dist,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", ">= 3.1", "< 5"

  s.add_development_dependency "rspec-rails"
end
