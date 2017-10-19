# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twobook/version'

Gem::Specification.new do |spec|
  spec.name          = 'twobook'
  spec.version       = Twobook::VERSION
  spec.authors       = ['Michael Parry']
  spec.email         = ['parry.my@gmail.com']

  spec.summary       = 'Double-entry accounting with superpowers'
  spec.description   = 'Database-optional double-entry accounting system with built-in corrections'
  spec.homepage      = 'https://github.com/parry-my/twobook'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'rb-readline', '~> 0.4.2'

  spec.add_runtime_dependency 'activesupport', '~> 4.0', '>= 4.0.0'
end
