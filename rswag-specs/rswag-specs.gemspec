$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rswag-specs"
  s.version     = ENV['TRAVIS_TAG'] || '0.0.0'
  s.authors     = ["Richie Morris"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/rswag"
  s.summary     = "A Swagger-based DSL for rspec-rails & accompanying rake task for generating Swagger files"
  s.description = "Simplify API integration testing with a succinct rspec DSL and generate Swagger files directly from your rspecs"
  s.license     = "MIT"

  s.files = Dir["{lib}/**/*"] + ["MIT-LICENSE", "Rakefile" ]

  s.add_dependency 'activesupport', '>= 3.1', '< 6.1'
  s.add_dependency 'railties', '>= 3.1', '< 6.1'
  s.add_dependency 'json-schema', '~> 2.2'
end
