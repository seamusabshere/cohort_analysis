module CohortAnalysis
  module ActiveRecordRelationInstanceMethods
    def cohort(characteristics, options = {})
      where cohort_constraint(characteristics, options)
    end

    def cohort_constraint(characteristics, options = {})
      options = options.symbolize_keys
      strategy = (options.delete(:strategy) || :big).to_s.camelcase
      Strategy.const_get(strategy).new(self, characteristics, options)
    end
  end
end
