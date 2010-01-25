Gem::Specification.new do |s|
  s.name = %q{ruby-smpp}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["August Z. Flatby"]
  s.date = %q{2009-08-20}
  s.description = %q{Ruby-implementation of the SMPP protocol, based on EventMachine. SMPP is a protocol that allows ordinary people outside the mobile network to exchange SMS messages directly with mobile operators.}
  s.email = ["august@apparat.no"]
  s.extra_rdoc_files = ["History.txt", "License.txt", "Manifest.txt", "README.rdoc", "CONTRIBUTORS.txt"]
  s.files = ["CONTRIBUTORS.txt", "History.txt", "License.txt", "Manifest.txt", "NEWS.txt", "Rakefile", "README.rdoc", "ruby-smpp.gemspec", "setup.rb", "config/hoe.rb", "config/requirements.rb", "examples/PDU1.example", "examples/PDU2.example", "examples/sample_gateway.rb", "examples/sample_smsc.rb", "lib/smpp.rb", "lib/sms.rb", "nbproject/project.properties", "nbproject/project.xml", "script/console", "script/destroy", "script/generate", "script/txt2html", "tasks/deployment.rake", "tasks/environment.rake", "test/smpp_test.rb", "test/test_helper.rb", "lib/smpp/base.rb", "lib/smpp/server.rb", "lib/smpp/transceiver.rb", "lib/smpp/version.rb", "nbproject/private/private.properties", "nbproject/private/rake-d.txt", "lib/smpp/pdu/base.rb", "lib/smpp/pdu/bind_base.rb", "lib/smpp/pdu/bind_resp_base.rb", "lib/smpp/pdu/bind_transceiver.rb", "lib/smpp/pdu/bind_transceiver_response.rb", "lib/smpp/pdu/deliver_sm.rb", "lib/smpp/pdu/deliver_sm_response.rb", "lib/smpp/pdu/enquire_link.rb", "lib/smpp/pdu/enquire_link_response.rb", "lib/smpp/pdu/generic_nack.rb", "lib/smpp/pdu/submit_multi.rb", "lib/smpp/pdu/submit_multi_response.rb", "lib/smpp/pdu/submit_sm.rb", "lib/smpp/pdu/submit_sm_response.rb", "lib/smpp/pdu/unbind.rb", "lib/smpp/pdu/unbind_response.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://ruby-smpp.rubyforge.org}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ruby-smpp}
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Ruby-implementation of the SMPP protocol, based on EventMachine. SMPP is a protocol that allows ordinary people outside the mobile network to exchange SMS messages directly with mobile operators.}
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
