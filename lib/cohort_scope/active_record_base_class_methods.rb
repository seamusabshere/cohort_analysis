module CohortScope
  module ActiveRecordBaseClassMethods
    def big_cohort(*args)
      scoped.big_cohort *args
    end

    def strict_cohort(*args)
      scoped.strict_cohort *args
    end
  end
end
