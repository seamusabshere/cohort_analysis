module CohortScope
  class BigCohort < Cohort
    # Reduce constraints by removing them one by one and counting the results.
    #
    # The constraint whose removal leads to the highest record count is removed from the overall constraint set.
    def self.reduce_constraints(active_record, constraints)
      most_restrictive_constraint = constraints.keys.max_by do |key|
        conditions = CohortScope.conditions_for constraints.except(key)
        active_record.scoped.where(conditions).count
      end
      constraints.except most_restrictive_constraint
    end
  end
end
