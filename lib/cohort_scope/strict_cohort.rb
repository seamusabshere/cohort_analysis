module CohortScope
  class StrictCohort < Cohort
    # Reduce constraints by removing the least important one.
    def self.reduce_constraints(active_record, constraints)
      constraints[0..-2]
    end
  end
end
