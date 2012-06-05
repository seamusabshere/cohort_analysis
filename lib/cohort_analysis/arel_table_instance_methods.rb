module CohortAnalysis
  module ArelTableInstanceMethods
    def cohort(*args)
      from(self).cohort *args
    end
  end
end
