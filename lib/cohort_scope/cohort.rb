require 'delegate'

module CohortScope
  class Cohort < ::Delegator

    class << self
      # Recursively look for a scope that meets the constraints and is at least <tt>minimum_cohort_size</tt>.
      def create(active_record, constraints, minimum_cohort_size)
        if constraints.none? # failing base case
          empty_scope = active_record.scoped.where Arel::Nodes::Equality.new(1,2)
          return new(empty_scope)
        end

        constrained_scope = active_record.scoped.where CohortScope.conditions_for(constraints)

        if constrained_scope.count >= minimum_cohort_size
          new constrained_scope
        else
          create active_record, reduce_constraints(active_record, constraints), minimum_cohort_size
        end
      end
    end

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

    # sabshere 2/1/11 overriding as_json per usual doesn't seem to work
    def to_json(*)
      as_json.to_json
    end
    
    def as_json(*)
      { :members => count }
    end

    # sabshere 2/1/11 ActiveRecord does this for #any? but not for #none?
    def none?(&blk)
      if block_given?
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
      "<Cohort scope with #{count} members>"
    end
  end
end
