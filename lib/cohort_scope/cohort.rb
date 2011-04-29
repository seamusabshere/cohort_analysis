require 'delegate'

module CohortScope
  class Cohort < ::Delegator

    class << self
      # Recursively look for a scope that meets the constraints and is at least <tt>minimum_cohort_size</tt>.
      def create(active_record, constraints, minimum_cohort_size)
        if constraints.none? # failing base case
          empty_scope = active_record.scoped.where '1 = 2'
          return new(empty_scope)
        end

        constrained_scope = active_record.scoped.where CohortScope.conditions_for(constraints)

        if constrained_scope.count >= minimum_cohort_size
          new constrained_scope
        else
          create active_record, reduce_constraints(active_record, constraints), minimum_cohort_size
        end
      end
    end

    def initialize(obj)
      super
      @_ch_obj = obj
    end
    def __getobj__
      @_ch_obj
    end
    def __setobj__(obj)
      @_ch_obj = obj
    end

    # sabshere 2/1/11 overriding as_json per usual doesn't seem to work
    def to_json(*)
      as_json.to_json
    end
    
    def as_json(*)
      { :members => count }
    end

    # sabshere 2/1/11 ActiveRecord does this for #any? but not for #none?
    def none?(&blk)
      if block_given?
        to_a.none? &blk
      else
        super
      end
    end

    def inspect
      "<Cohort scope with #{count} members>"
    end
  end
end
