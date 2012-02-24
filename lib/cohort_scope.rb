require 'active_record'
require 'active_support/core_ext'

require 'cohort_scope/cohort'
require 'cohort_scope/big_cohort'
require 'cohort_scope/strict_cohort'
require 'cohort_scope/active_record_relation_to_cohort'

module CohortScope
  def self.extended(klass)
    klass.class_eval do
      class << self
        attr_accessor :minimum_cohort_size
      end
    end
  end
  
  def self.conditions_for(characteristics)
    case characteristics
    when ::Array
      characteristics.inject({}) { |memo, (k, v)| memo[k] = v; memo }
    when ::Hash
      characteristics.dup
    end
  end
  
  # Find the biggest scope possible by removing characteristics <b>in any order</b>.
  # Returns an empty scope if it can't meet the minimum scope size.
  def big_cohort(characteristics, options = {})
    BigCohort.stub scoped, characteristics, (options[:minimum_cohort_size] || minimum_cohort_size)
  end

  # Find the first acceptable scope by removing characteristics <b>in strict order</b>, starting with the last characteristic.
  # Returns an empty scope if it can't meet the minimum scope size.
  #
  # <tt>characteristics</tt> must be key/value pairs (splat if it's an array)
  #
  # Note that the first characteristic is implicitly required.
  #
  # Take this example, where favorite color is considered to be "more important" than birthdate:
  #
  #   ordered_characteristics = [ [:favorite_color, 'heliotrope'], [:birthdate, '1999-01-01'] ]
  #   Citizen.strict_cohort(*ordered_characteristics) #=> [...]
  #
  # If the original characteristics don't meet the minimum scope size, then the only characteristic that can be removed is birthdate.
  # In other words, this would never return a scope that was constrained on birthdate but not on favorite_color.
  def strict_cohort(*args)
    args = args.dup
    options = args.last.is_a?(::Hash) ? args.pop : {}
    characteristics = args
    StrictCohort.stub scoped, characteristics, (options[:minimum_cohort_size] || minimum_cohort_size)
  end
end
