module CohortScope
  class Cohort < ::Arel::Nodes::Node
    IMPOSSIBLE = '1 = 2'

    def initialize(active_record, characteristics, minimum_cohort_size)
      @active_record = active_record
      @characteristics = characteristics
      @minimum_cohort_size = minimum_cohort_size
    end

    def expr
      @expr ||= resolve
    end
    alias :to_sql :expr

    private

    # Recursively look for a scope that meets the characteristics and is at least <tt>minimum_cohort_size</tt>.
    def resolve
      if @characteristics.empty?
        IMPOSSIBLE
      elsif (current = @active_record.where(CohortScope.conditions_for(@characteristics))).count >= @minimum_cohort_size
        current.constraints.inject(:and).to_sql
      else
        @characteristics = self.class.reduce_characteristics(@active_record, @characteristics)
        resolve
      end
    end
  end
end
