require 'delegate'
module CohortScope
  class Cohort < ::Delegator
    class Stub
      def initialize(cohort_class, relation, constraints, minimum_cohort_size)
        @cohort_class = cohort_class
        @relation = relation
        @constraints = constraints
        @minimum_cohort_size = minimum_cohort_size
      end
      def respond_to?(*)
        true
      end
      def method_missing(method_id, *args, &blk)
        cohort = @cohort_class.resolve @relation, @constraints, @minimum_cohort_size
        @delegator.__setobj__ cohort
        @delegator.send method_id, *args, &blk
      end
    end
    
    class << self
      def stub(relation, constraints, minimum_cohort_size)
        cohort = new Stub.new(self, relation, constraints, minimum_cohort_size)
        cohort.__getobj__.instance_variable_set(:@delegator, cohort)
        cohort
      end

      # Recursively look for a scope that meets the constraints and is at least <tt>minimum_cohort_size</tt>.
      def resolve(relation, constraints, minimum_cohort_size)
        if constraints.none? # failing base case
          cohort = new relation.where(IMPOSSIBLE_CONDITION)
          cohort.count = 0
          return cohort
        end
        constrained_scope = relation.where CohortScope.conditions_for(constraints)
        if (count = constrained_scope.count) >= minimum_cohort_size
          cohort = new constrained_scope
          cohort.count = count
          cohort
        else
          resolve relation, reduce_constraints(relation, constraints), minimum_cohort_size
        end
      end
    end
    
    IMPOSSIBLE_CONDITION = ::Arel::Nodes::Equality.new(1,2)

    def initialize(obj)
      super
      @stub_or_relation = obj
    end
    def __getobj__
      @stub_or_relation
    end
    def __setobj__(obj)
      @stub_or_relation = obj
    end
    
    def stub?
      __getobj__.is_a?(Stub)
    end

    def count=(int)
      @count = int
    end
    
    def count
      @count ||= super
    end
    
    def size
      count
    end

    # sabshere 2/1/11 overriding as_json per usual doesn't seem to work
    def to_json(*)
      as_json.to_json
    end
    
    def as_json(*)
      { :members => count }
    end
    
    def empty?
      count == 0
    end
        
    def any?
      return false if count == 0
      return true if !block_given? and count > 0
      super
    end

    def none?
      return true if count == 0
      return false if !block_given? and count > 0
      super
    end
    
    def +(other)
      case other
      when Cohort
        combined_conditions = (constraints + other.constraints).map(&:to_sql).join(' OR ')
        Cohort.new __getobj__.klass.where(combined_conditions)
      else
        super
      end
    end

    def inspect
      "#<#{self.class.name} with #{count} members>"
    end
  end
end
