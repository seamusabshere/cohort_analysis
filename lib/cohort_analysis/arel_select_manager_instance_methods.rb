module CohortAnalysis
  module ArelSelectManagerInstanceMethods
    # @return [Arel::SelectManager]
    def cohort(characteristics, options = {})
      where Strategy.create(self, characteristics, options)
    end

    # If a cohort has been constructed using this Arel::SelectManager, then this will tell you whether it was successful (posssible) or not.
    # @return [true,false,nil]
    def cohort_possible?
      @cohort_possible_query
    end

    # @private
    def cohort_possible!
      @cohort_possible_query = true
    end

    # @private
    def cohort_impossible!
      @cohort_possible_query = false
    end
  end
end
