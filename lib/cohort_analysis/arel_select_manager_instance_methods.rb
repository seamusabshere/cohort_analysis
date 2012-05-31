module CohortAnalysis
  module ArelSelectManagerInstanceMethods
    # @return [Arel::SelectManager]
    def cohort(characteristics, options = {})
      where Strategy.create(self, characteristics, options)
    end
  end
end
