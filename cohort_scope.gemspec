# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cohort_scope}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Seamus Abshere", "Andy Rossmeissl", "Derek Kastner"]
  s.date = %q{2010-07-07}
  s.description = %q{Provides big_cohort, which widens by finding the constraint that eliminates the most records and removing it. Also provides strict_cohort, which widens by eliminating constraints in order.}
  s.email = %q{seamus@abshere.net}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "cohort_scope.gemspec",
     "lib/cohort_scope.rb",
     "test/helper.rb",
     "test/test_cohort_scope.rb"
  ]
  s.homepage = %q{http://github.com/seamusabshere/cohort_scope}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Provides cohorts (in the form of ActiveRecord scopes) that dynamically widen until they contain a certain number of records.}
  s.test_files = [
    "test/helper.rb",
     "test/test_cohort_scope.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.0.beta2"])
      s.add_runtime_dependency(%q<activerecord>, [">= 3.0.0.beta2"])
      s.add_development_dependency(%q<shoulda>, [">= 2.10.3"])
    else
      s.add_dependency(%q<activesupport>, [">= 3.0.0.beta2"])
      s.add_dependency(%q<activerecord>, [">= 3.0.0.beta2"])
      s.add_dependency(%q<shoulda>, [">= 2.10.3"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 3.0.0.beta2"])
    s.add_dependency(%q<activerecord>, [">= 3.0.0.beta2"])
    s.add_dependency(%q<shoulda>, [">= 2.10.3"])
  end
end
