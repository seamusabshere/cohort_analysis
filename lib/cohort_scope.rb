require 'active_record'
require 'active_support'
require 'active_support/version'

require 'active_support/core_ext/module/delegation' if ActiveSupport::VERSION::MAJOR == 3

require 'cohort_scope/version'
require 'cohort_scope/cohort'
require 'cohort_scope/big_cohort'
require 'cohort_scope/strict_cohort'

module CohortScope
  def self.extended(klass)
    klass.cattr_accessor :minimum_cohort_size, :instance_writer => false
  end

  # Find the biggest scope possible by removing constraints <b>in any order</b>.
  # Returns an empty scope if it can't meet the minimum scope size.
  def big_cohort(constraints = {}, custom_minimum_cohort_size = self.minimum_cohort_size)
    raise ArgumentError, "You can't give a big_cohort an OrderedHash; do you want strict_cohort?" if constraints.is_a?(ActiveSupport::OrderedHash)
    BigCohort.create self, constraints, custom_minimum_cohort_size
  end

  # Find the first acceptable scope by removing constraints <b>in strict order</b>, starting with the last constraint.
  # Returns an empty scope if it can't meet the minimum scope size.
  #
  # <tt>constraints</tt> must be an <tt>ActiveSupport::OrderedHash</tt> (no support for ruby 1.9's natively ordered hashes yet).
  #
  # Note that the first constraint is implicitly required.
  #
  # Take this example, where favorite color is considered to be "more important" than birthdate:
  #
  #   ordered_constraints = ActiveSupport::OrderedHash.new
  #   ordered_constraints[:favorite_color] = 'heliotrope'
  #   ordered_constraints[:birthdate] = '1999-01-01'
  #   Citizen.strict_cohort(ordered_constraints) #=> [...]
  #
  # If the original constraints don't meet the minimum scope size, then the only constraint that can be removed is birthdate.
  # In other words, this would never return a scope that was constrained on birthdate but not on favorite_color.
  def strict_cohort(constraints, custom_minimum_cohort_size = self.minimum_cohort_size)
    raise ArgumentError, "You need to give strict_cohort an OrderedHash" unless constraints.is_a?(ActiveSupport::OrderedHash)
    StrictCohort.create self, constraints, custom_minimum_cohort_size
  end
end
