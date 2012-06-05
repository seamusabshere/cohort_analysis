# -*- encoding: utf-8 -*-
require File.expand_path('../lib/cohort_analysis/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Seamus Abshere", "Andy Rossmeissl", "Derek Kastner", "Ian Hough"]
  gem.email         = ["seamus@abshere.net", 'andy@rossmeissl.net', 'dkastner@gmail.com', 'ijhough@gmail.com']
  desc = %q{Lets you do cohort analysis based on two strategies: "big", which discards characteristics for the maximum cohort result, and "strict", which discards characteristics in order until a minimum cohort size is reached.}
  gem.description   = desc
  gem.summary       = desc
  gem.homepage      = "https://github.com/seamusabshere/cohort_analysis"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "cohort_analysis"
  gem.require_paths = ["lib"]
  gem.version       = CohortAnalysis::VERSION

  gem.add_runtime_dependency 'activesupport', '>=3'
  gem.add_runtime_dependency 'arel', '>=3'
  
  gem.add_development_dependency 'activerecord', '>=3'
  gem.add_development_dependency 'active_record_inline_schema'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'minitest-reporters'
  gem.add_development_dependency 'yard'
  if RUBY_VERSION >= '1.9'
    gem.add_development_dependency 'factory_girl'
  else
    gem.add_development_dependency 'factory_girl', '~>2'
  end
  if RUBY_PLATFORM == 'java'
    gem.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
  else
    gem.add_development_dependency 'sqlite3'
  end

  # gem.add_development_dependency 'debugger'
end
