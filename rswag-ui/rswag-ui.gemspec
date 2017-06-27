$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'rswag/ui/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rswag-ui"
  s.version     = Rswag::Ui::VERSION
  s.authors     = ["Richie Morris"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/rswag"
  s.summary     = "A Rails Engine that includes swagger-ui and powers it from configured Swagger endpoints"
  s.description = "Expose beautiful API documentation, that's powered by Swagger JSON endpoints, including a UI to explore and test operations"
  s.license     = "MIT"

  s.files = Dir["{app,config,lib,vendor}/**/*"] + ["MIT-LICENSE", "Rakefile" ]

  s.add_dependency "rails", ">= 3.1", "< 5.2" 
end
