# -*- encoding: utf-8 -*-

require File.expand_path('../lib/pry-moves/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'pry-moves'
  gem.version       = PryMoves::VERSION
  gem.author        = 'Garmoshka Mo'
  gem.email         = 'dan@coav.ru'
  gem.license       = 'MIT'
  gem.homepage      = 'https://github.com/garmoshka-mo/pry-moves'
  gem.summary       = 'Simple execution navigation for Pry.'
  gem.description   = "Turn Pry into a primitive debugger. Adds 'step' and 'next' commands to control execution."

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

  # Dependencies
  gem.required_ruby_version = '>= 1.8.7'
  gem.add_runtime_dependency 'pry', '>= 0.9.10', '< 0.11.0'
  gem.add_runtime_dependency 'binding_of_caller', '>= 0.7'
  gem.add_development_dependency 'pry-remote', '~> 0.1.6'
end
