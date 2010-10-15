require 'delegate'

module CohortScope
  class Cohort < Delegator

    class << self
      # Recursively look for a scope that meets the constraints and is at least <tt>minimum_cohort_size</tt>.
      def create(model, constraints, custom_minimum_cohort_size)
        raise RuntimeError, "You need to set #{name}.minimum_cohort_size = X" unless model.minimum_cohort_size.present?
        
        if constraints.values.none? # failing base case
          empty_cohort = model.scoped.where '1 = 2'
          return new(empty_cohort)
        end

        constraint_hash = sanitize_constraints model, constraints
        constrained_scope = model.scoped.where(constraint_hash)

        if constrained_scope.count >= custom_minimum_cohort_size
          new constrained_scope
        else
          reduced_constraints = reduce_constraints(model, constraints)
          create(model, reduced_constraints, custom_minimum_cohort_size)
        end
      end
      
      # Sanitize constraints by
      # * removing nil constraints (so constraints like "X IS NULL" are impossible, sorry)
      # * converting ActiveRecord::Base objects into integer foreign key constraints
      def sanitize_constraints(constraints)
        new_hash = constraints.is_a?(ActiveSupport::OrderedHash) ? ActiveSupport::OrderedHash.new : Hash.new
        conditions = constraints.inject(new_hash) do |memo, tuple|
          k, v = tuple
          if v.kind_of?(ActiveRecord::Base)
            condition = { association_primary_key(k) => v.to_param }
          elsif !v.nil?
            condition = { k => v }
          end
          memo.merge! condition if condition.is_a? Hash
          memo
        end
        conditions
      end
      
      # Convert constraints that are provided as ActiveRecord::Base objects into their corresponding integer primary keys.
      #
      # Only works for <tt>belongs_to</tt> relationships.
      #
      # For example, :car => <#Car> might get translated into :car_id => 44.
      def association_primary_key(model, name)
        @_cohort_association_primary_keys ||= {}
        return @_cohort_association_primary_keys[name] if @_cohort_association_primary_keys.has_key? name
        a = model.reflect_on_association name
        raise "there is no association #{name.inspect} on #{model}" if a.nil?
        raise "can't use cohort scope on :through associations (#{self.name} #{name})" if a.options.has_key? :through
        if !a.primary_key_name.blank?
          @_cohort_association_primary_keys[name] = a.primary_key_name
        else
          raise "we need some other way to find primary key"
        end
      end
    end

    def initialize(obj)
      @_ch_obj = obj
    end
    def __getobj__
      @_ch_obj
    end

    def as_json(*)
      { :members => count }
    end

    def inspect
      "<Massive ActiveRecord scope with #{count} members>"
    end
  end
end
