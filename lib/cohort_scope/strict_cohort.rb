module CohortScope
  class StrictCohort < Cohort
    
    # (Used by <tt>strict_cohort</tt>)
    #
    # Reduce constraints by removing the least important one.
    def self.reduce_constraints(model, constraints)
      reduced_constraints = constraints.dup
      reduced_constraints.delete constraints.keys.last
      reduced_constraints
    end
  end
end
