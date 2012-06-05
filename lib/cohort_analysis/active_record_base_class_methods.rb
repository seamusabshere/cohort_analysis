module CohortAnalysis
  module ActiveRecordBaseClassMethods
    def cohort(*args)
      scoped.cohort *args
    end
  end
end
