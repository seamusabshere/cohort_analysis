module CohortAnalysis
  class Strategy < ::Arel::Nodes::Node
    class << self
      def create(select_manager, characteristics, options = {})
        options = options.symbolize_keys
        strategy = if options.has_key? :strategy
          options[:strategy]
        elsif options.has_key? :priority
          :strict
        else
          DEFAULT_STRATEGY
        end
        const_get(strategy.to_s.camelcase).new(select_manager, characteristics, options)
      end
    end

    class AlwaysTrue
      class << self; def to_sql; '1 = 1'; end; end
    end
    class Impossible
      class << self; def to_sql; '1 = 2'; end; end
    end

    DEFAULT_STRATEGY = :big

    attr_accessor :select_manager
    attr_reader :original
    attr_reader :current
    attr_reader :minimum_size

    def initialize(select_manager, characteristics, options = {})
      @select_manager = select_manager
      @original = characteristics.dup
      @current = characteristics.dup
      @minimum_size = options.fetch(:minimum_size, 1)
      @final_mutex = ::Mutex.new
    end

    def final
      return @final if @final
      @final_mutex.synchronize do
        return @final if @final
        resolve!
        @final
      end
    end

    def expr
      final.to_sql
    end

    private

    # Recursively look for a scope that meets the characteristics and is at least <tt>minimum_size</tt>.
    def resolve!
      if original.empty?
        @final = AlwaysTrue
      elsif current.empty?
        @final = Impossible
      elsif count(current) >= minimum_size
        @final = grasp(current).inject(:and)
      else
        reduce!
        resolve!
      end
    end

    def grasp(subset)
      subset.map { |k, v| table[k].eq(v) }
    end

    def count(subset)
      merged_constraints = (select_manager.constraints + grasp(subset)).inject(nil) do |memo, constraint|
        if (constraint.is_a?(Strategy) and constraint == self)# or (constraint.is_a?(Arel::Nodes::Grouping) and constraint.expr == self)
          next memo
        end
        if constraint.is_a?(String)
          constraint = Arel::Nodes::Grouping.new(constraint)
        end
        if memo
          memo.and(constraint)
        else
          constraint
        end
      end
      sql = table.project('COUNT(*)').where(merged_constraints).to_sql
      select_manager.engine.connection.select_value(sql).to_i
    end

    def table
      select_manager.source.left
    end
  end
end
