require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "cohort_scope"
    gem.summary = %Q{Provides cohorts (in the form of ActiveRecord scopes) that dynamically widen until they contain a certain number of records.}
    gem.description = %Q{Provides big_cohort, which widens by finding the constraint that eliminates the most records and removing it. Also provides strict_cohort, which widens by eliminating constraints in order.}
    gem.email = "seamus@abshere.net"
    gem.homepage = "http://github.com/seamusabshere/cohort_scope"
    gem.authors = ["Seamus Abshere", "Andy Rossmeissl", "Derek Kastner"]
    gem.add_dependency "activesupport", ">=3.0.0.beta4"
    gem.add_dependency "activerecord", ">=3.0.0.beta4"
    gem.add_development_dependency "shoulda", ">= 2.10.3"
    gem.add_development_dependency 'sqlite3-ruby'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "cohort_scope #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
