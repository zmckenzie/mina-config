# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mina/config/version'

Gem::Specification.new do |spec|
  spec.name          = "mina-config"
  spec.version       = Mina::Config::VERSION
  spec.authors       = ["Zachary Mckenzie"]
  spec.email         = ["Zachary.Mckenzie@agapered.com"]
  spec.summary       = %q{Adds a multi-environment yml configuration file to mina}
  spec.description   = %q{Adds a multi-environment yml configuration file to mina. Environment configuration is dynamically created by the definitions in the deploy.yml file.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mina"
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
