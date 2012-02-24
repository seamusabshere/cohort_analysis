module CohortScope
  class StrictCohort < Cohort
    # Reduce characteristics by removing the least important one.
    def self.reduce_characteristics(active_record, characteristics)
      characteristics[0..-2]
    end
  end
end
