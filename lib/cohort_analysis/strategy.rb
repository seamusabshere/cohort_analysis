module CohortAnalysis
  class Strategy < ::Arel::Nodes::Node
    IMPOSSIBLE = '1 = 2'

    def initialize(active_record_relation, characteristics, options = {})
      @active_record_relation = active_record_relation
      @characteristics = characteristics
      @reduced_characteristics = characteristics.dup
      @minimum_size = options.fetch(:minimum_size, 1)
    end

    def expr
      @expr ||= resolve!
    end
    alias :to_sql :expr

    private

    # Recursively look for a scope that meets the characteristics and is at least <tt>minimum_size</tt>.
    def resolve!
      if @reduced_characteristics.empty?
        IMPOSSIBLE
      elsif (current = @active_record_relation.where(CohortAnalysis.conditions_for(@reduced_characteristics))).count >= @minimum_size
        current.constraints.inject(:and).to_sql
      else
        reduce!
        resolve!
      end
    end
  end
end
