# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cohort_scope/version"

Gem::Specification.new do |s|
  s.name        = "cohort_scope"
  s.version     = CohortScope::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere", "Andy Rossmeissl", "Derek Kastner"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/cohort_scope"
  s.summary     = %Q{Provides cohorts (in the form of ActiveRecord scopes) that dynamically widen until they contain a certain number of records.}
  s.description = %Q{Provides big_cohort, which widens by finding the constraint that eliminates the most records and removing it. Also provides strict_cohort, which widens by eliminating constraints in order.}

  s.rubyforge_project = "cohort_scope"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "activesupport", "~> 3.0.0"
  s.add_dependency "activerecord", "~> 3.0.0"
  s.add_development_dependency "shoulda", ">= 2.10.3"
  s.add_development_dependency 'sqlite3-ruby'
end
