module CohortScope
  module ActiveRecordRelationToCohort
    def to_cohort
      Cohort.new self
    end
  end
end

::ActiveRecord::Relation.send :include, ::CohortScope::ActiveRecordRelationToCohort
