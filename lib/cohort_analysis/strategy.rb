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

    module AlwaysTrue
      def self.to_sql; '1 = 1' end
    end
    module Impossible
      def self.to_sql; '1 = 2' end
    end

    DEFAULT_STRATEGY = :big

    attr_reader :select_manager
    attr_reader :original
    attr_reader :current
    attr_reader :minimum_size
    attr_reader :table_name
    attr_reader :table

    def initialize(select_manager, characteristics, options = {})
      @select_manager = select_manager
      @table_name = select_manager.source.left.name
      @table = Arel::Table.new table_name
      @original = characteristics.dup
      @current = characteristics.dup
      @minimum_size = options.fetch(:minimum_size, 1)
      @final_mutex = Mutex.new
    end

    def final
      @final || if @final_mutex.try_lock
        begin
          @final ||= resolve!
        ensure
          @final_mutex.unlock
        end
      else
        Impossible
      end
    end

    def expr
      final.to_sql
    end

    def ==(other)
      other.is_a?(Strategy) and
        table_name == other.table_name and
        minimum_size = other.minimum_size and
        original == other.original
    end

    private

    # Recursively look for a scope that meets the characteristics and is at least <tt>minimum_size</tt>.
    def resolve!
      if original.empty?
        select_manager.cohort_possible!
        AlwaysTrue
      elsif current.empty?
        select_manager.cohort_impossible!
        Impossible
      elsif count(current) >= minimum_size
        select_manager.cohort_possible!
        grasp(current).inject :and
      else
        reduce!
        resolve!
      end
    end

    def grasp(subset)
      subset.map do |k, v|
        case v
        when Array, Range
          table[k].in v
        else
          table[k].eq v
        end
      end
    end

    def other_constraints
      select_manager.constraints.reject do |constraint|
        self == constraint
      end
    end

    def count(subset)
      constraints = grasp subset

      other_constraints.each do |constraint|
        if constraint.is_a? String
          constraint = Arel::Nodes::Grouping.new constraint
        end
        constraints << constraint
      end

      relation = constraints.inject(nil) do |memo, constraint|
        if memo
          memo.and(constraint)
        else
          constraint
        end
      end

      sql = table.dup.project('COUNT(*)').where(relation).to_sql
      select_manager.engine.connection.select_value(sql).to_i
    end
  end
end
