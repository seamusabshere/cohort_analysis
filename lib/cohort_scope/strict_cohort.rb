module CohortScope
  class StrictCohort < Cohort
    # Reduce characteristics by removing the least important one.
    def reduce!
      @reduced_characteristics.pop
    end
  end
end
