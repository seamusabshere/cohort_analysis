require 'active_record'

require 'active_support'
require 'active_support/version'
if ActiveSupport::VERSION::MAJOR == 3
  require 'active_support/json'
  require 'active_support/core_ext/hash'
end

module CohortScope
  autoload :Cohort, 'cohort_scope/cohort'
  autoload :BigCohort, 'cohort_scope/big_cohort'
  autoload :StrictCohort, 'cohort_scope/strict_cohort'
  
  def self.extended(klass)
    klass.class_eval do
      class << self
        attr_accessor :minimum_cohort_size
      end
    end
  end
  
  def self.conditions_for(constraints)
    case constraints
    when ::Array
      constraints.inject({}) { |memo, (k, v)| memo[k] = v; memo }
    when ::Hash
      constraints.dup
    end
  end
  
  # Find the biggest scope possible by removing constraints <b>in any order</b>.
  # Returns an empty scope if it can't meet the minimum scope size.
  def big_cohort(constraints, options = {})
    BigCohort.create self, constraints, (options[:minimum_cohort_size] || minimum_cohort_size)
  end

  # Find the first acceptable scope by removing constraints <b>in strict order</b>, starting with the last constraint.
  # Returns an empty scope if it can't meet the minimum scope size.
  #
  # <tt>constraints</tt> must be key/value pairs (splat if it's an array)
  #
  # Note that the first constraint is implicitly required.
  #
  # Take this example, where favorite color is considered to be "more important" than birthdate:
  #
  #   ordered_constraints = [ [:favorite_color, 'heliotrope'], [:birthdate, '1999-01-01'] ]
  #   Citizen.strict_cohort(*ordered_constraints) #=> [...]
  #
  # If the original constraints don't meet the minimum scope size, then the only constraint that can be removed is birthdate.
  # In other words, this would never return a scope that was constrained on birthdate but not on favorite_color.
  def strict_cohort(*args)
    args = args.dup
    options = args.last.is_a?(::Hash) ? args.pop : {}
    constraints = args
    StrictCohort.create self, constraints, (options[:minimum_cohort_size] || minimum_cohort_size)
  end
end
