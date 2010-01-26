require 'rake'

Gem::Specification.new do |s|
  s.name = %q{ruby-smpp}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["August Z. Flatby"]
  s.date = %q{2009-08-20}
  s.summary = %q{Ruby-implementation of the SMPP protocol, based on EventMachine. SMPP is a protocol that allows ordinary people outside the mobile network to exchange SMS messages directly with mobile operators.}
  s.email = ["august@apparat.no"]
  s.extra_rdoc_files = ["History.txt", "License.txt", "Manifest.txt", "README.rdoc", "CONTRIBUTORS.txt"]
  s.files = FileList['lib/**/*.rb', 'script/*', '[A-Z]*', 'test/**/*.rb', 'config/*', 'examples/*', 'tasks/*'].to_a
  s.has_rdoc = true
  s.homepage = %q{http://ruby-smpp.rubyforge.org}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ruby-smpp}
  s.rubygems_version = %q{1.3.3}
  s.description = s.summary + " The implementation is based on the Ruby/EventMachine library."
  s.test_files = ["test/smpp_test.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.10.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.10.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.10.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
