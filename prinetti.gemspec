$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "prinetti/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "prinetti"
  s.version     = Prinetti::VERSION
  s.authors     = ["Joakim Runeberg"]
  s.email       = ["joakim.runeberg@gmail.com"]
  s.homepage    = "http://agencyleroy.com"
  s.summary     = "Ruby integration for the Itella Prinetti API"
  s.description = "Will write more."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.5"
  s.add_dependency "digest"
  s.add_dependency "httparty"

  s.add_development_dependency "sqlite3"
end
