require 'delegate'

module CohortScope
  class Cohort < ::Delegator
    class << self
      # Recursively look for a scope that meets the constraints and is at least <tt>minimum_cohort_size</tt>.
      def create(active_record, constraints, minimum_cohort_size)
        if constraints.none? # failing base case
          cohort = new active_record.scoped.where(IMPOSSIBLE_CONDITION)
          cohort.count = 0
          return cohort
        end

        constrained_scope = active_record.scoped.where CohortScope.conditions_for(constraints)

        if (count = constrained_scope.count) >= minimum_cohort_size
          cohort = new constrained_scope
          cohort.count = count
          cohort
        else
          create active_record, reduce_constraints(active_record, constraints), minimum_cohort_size
        end
      end
    end
    
    IMPOSSIBLE_CONDITION = ::Arel::Nodes::Equality.new(1,2)

    def initialize(obj)
      super
      @_ch_obj = obj
    end
    def __getobj__
      @_ch_obj
    end
    def __setobj__(obj)
      @_ch_obj = obj
    end

    def count=(int)
      @count = int
    end
    
    def count
      @count ||= super
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

    def none?(&blk)
      return true if count == 0
      return false if !block_given? and count > 0
      if block_given?
        # sabshere 2/1/11 ActiveRecord does this for #any? but not for #none?
        to_a.none? &blk
      else
        super
      end
    end
    
    def where_value_nodes
      __getobj__.instance_variable_get(:@where_values)
    end
    
    def active_record
      __getobj__.klass
    end
    
    def +(other)
      case other
      when Cohort
        combined_conditions = (where_value_nodes + other.where_value_nodes).inject(nil) do |memo, node|
          if memo.nil?
            node
          else
            memo.or(node)
          end
        end
        Cohort.new active_record.where(combined_conditions)
      else
        super
      end
    end

    def inspect
      "#<#{self.class.name} with #{count} members>"
    end
  end
end
