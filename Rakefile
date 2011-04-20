require File.expand_path('../config/environment', __FILE__)
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.name = "ruby-smpp"
    gem.summary = %Q{Ruby implementation of the SMPP protocol, based on EventMachine.}
    gem.description = gem.summary + " SMPP is a protocol that allows ordinary people outside the mobile network to exchange SMS messages directly with mobile operators."
    gem.email = "raykrueger@gmail.com"
    gem.homepage = "http://github.com/raykrueger/ruby-smpp"
    gem.authors = ["Ray Krueger", "August Z. Flatby"]
    gem.rubyforge_project = gem.name

    gem.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "CONTRIBUTORS.txt"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ruby-smpp #{version}"
  rdoc.rdoc_files.include('README*', "CHANGELOG", "CONTRIBUTORS.txt", "LICENSE")
  rdoc.rdoc_files.include('lib/**/*.rb')
end
