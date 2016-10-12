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

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile" ]

  s.add_dependency "rails", ">= 3.1", "< 5.1" 
end
