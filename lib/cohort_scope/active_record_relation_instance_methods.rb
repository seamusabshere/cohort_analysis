module CohortScope
  module ActiveRecordRelationInstanceMethods
    # Find the biggest scope possible by removing characteristics <b>in any order</b>.
    # Returns an empty scope if it can't meet the minimum scope size.
    def big_cohort(characteristics, options = {})
      BigCohort.new self, characteristics, (options[:minimum_cohort_size] || (klass.respond_to?(:minimum_cohort_size) ? klass.minimum_cohort_size : nil))
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
      StrictCohort.new self, characteristics, (options[:minimum_cohort_size] || (klass.respond_to?(:minimum_cohort_size) ? klass.minimum_cohort_size : nil))
    end
  end
end
