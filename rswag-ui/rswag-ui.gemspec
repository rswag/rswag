$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rswag-ui"
  s.version     = ENV['TRAVIS_TAG'] || '0.0.0'
  s.authors     = ["Richie Morris"]
  s.email       = ["domaindrivendev@gmail.com"]
  s.homepage    = "https://github.com/domaindrivendev/rswag"
  s.summary     = "A Rails Engine that includes swagger-ui and powers it from configured Swagger endpoints"
  s.description = "Expose beautiful API documentation, that's powered by Swagger JSON endpoints, including a UI to explore and test operations"
  s.license     = "MIT"

  s.files = Dir.glob("{lib,node_modules}/**/*") + ["MIT-LICENSE", "Rakefile" ]

  s.add_dependency 'actionpack', '>=3.1', '< 6.1'
  s.add_dependency 'railties', '>= 3.1', '< 6.1'
end
