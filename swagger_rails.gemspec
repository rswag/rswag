$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "swagger_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "swagger_rails"
  s.version     = SwaggerRails::VERSION
  s.authors     = ["domaindrivendev"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/swagger_rails"
  s.summary     = "Generate API documentation, including a slick discovery/playground UI, directly from your rspec integration specs"
  s.description = "Use the provided DSL to describe and test API operations in your spec files. Then, you can easily generate corresponding swagger.json files and serve them up with an embedded version of swagger-ui. Best of all, it requires minimal coding and maintenance, allowing you to focus on building an awesome API!"
  s.license     = "MIT"

  s.files = Dir["{app,bower_components/swagger-ui/dist,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency 'rack'
  s.add_dependency "rails", ">= 3.1", "<= 5"

  s.add_development_dependency "rspec-rails", "~> 3.0"
end
