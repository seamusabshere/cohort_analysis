module CohortScope
  class BigCohort < Cohort
    # Reduce constraints by removing them one by one and counting the results.
    #
    # The constraint whose removal leads to the highest record count is removed from the overall constraint set.
    def self.reduce_constraints(model, constraints)
      highest_count_after_removal = nil
      losing_key = nil
      constraints.keys.each do |key|
        test_constraints = constraints.except(key)
        count_after_removal = model.scoped.where(sanitize_constraints(test_constraints)).count
        if highest_count_after_removal.nil? or count_after_removal > highest_count_after_removal
          highest_count_after_removal = count_after_removal
          losing_key = key
        end
      end
      constraints.except losing_key
    end
  end
end
