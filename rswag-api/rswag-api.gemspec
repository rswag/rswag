$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rswag-api"
  s.version     = ENV['TRAVIS_TAG'] || '0.0.0'
  s.authors     = ["Richie Morris"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/rswag"
  s.summary     = "A Rails Engine that exposes Swagger files as JSON endpoints"
  s.description = "Open up your API to the phenomenal Swagger ecosystem by exposing Swagger files, that describe your service, as JSON endpoints"
  s.license     = "MIT"

  s.files = Dir["{lib}/**/*"] + ["MIT-LICENSE", "Rakefile"]

  s.add_dependency 'railties', '>= 3.1', '< 6.1'
end
