# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smpp/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby-smpp"
  spec.version       = Smpp::VERSION
  spec.authors       = ["Ray Krueger", "August Z. Flatby"]
  spec.email         = ["raykrueger@gmail.com"]
  spec.description   = %q{Ruby implementation of the SMPP protocol, based on EventMachine. SMPP is a protocol that allows ordinary people outside the mobile network to exchange SMS messages directly with mobile operators.}
  spec.summary       = %q{Ruby implementation of the SMPP protocol, based on EventMachine.}
  spec.homepage      = "http://github.com/raykrueger/ruby-smpp"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "eventmachine", ">= 0.10.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
