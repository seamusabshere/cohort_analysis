module CohortScope
  class BigCohort < Cohort
    # Reduce characteristics by removing them one by one and counting the results.
    #
    # The characteristic whose removal leads to the highest record count is removed from the overall characteristic set.
    def self.reduce_characteristics(active_record, characteristics)
      if characteristics.keys.length < 2
        return {}
      end
      most_restrictive_characteristic = characteristics.keys.max_by do |key|
        conditions = CohortScope.conditions_for characteristics.except(key)
        active_record.where(conditions).count
      end
      characteristics.except most_restrictive_characteristic
    end
  end
end
