module CohortScope
  class Cohort < ::Arel::Nodes::Node
    IMPOSSIBLE = '1 = 2'

    def initialize(active_record_relation, characteristics, minimum_cohort_size)
      @active_record_relation = active_record_relation
      @characteristics = characteristics
      @minimum_cohort_size = minimum_cohort_size
    end

    def expr
      @expr ||= resolve(@characteristics)
    end
    alias :to_sql :expr

    private

    # Recursively look for a scope that meets the characteristics and is at least <tt>minimum_cohort_size</tt>.
    def resolve(reduced_characteristics)
      if reduced_characteristics.empty?
        IMPOSSIBLE
      elsif (current = @active_record_relation.where(CohortScope.conditions_for(reduced_characteristics))).count >= @minimum_cohort_size
        current.constraints.inject(:and).to_sql
      else
        resolve self.class.reduce_characteristics(@active_record_relation, reduced_characteristics)
      end
    end
  end
end
