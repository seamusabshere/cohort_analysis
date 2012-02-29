module CohortAnalysis
  module ActiveRecordBaseClassMethods
    def cohort(*args)
      scoped.cohort *args
    end

    def cohort_constraint(*args)
      scoped.cohort_constraint *args
    end
  end
end
