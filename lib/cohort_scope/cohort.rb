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
      def sanitize_constraints(model, constraints)
        new_hash = constraints.is_a?(ActiveSupport::OrderedHash) ? ActiveSupport::OrderedHash.new : Hash.new
        conditions = constraints.inject(new_hash) do |memo, tuple|
          k, v = tuple
          if v.kind_of?(ActiveRecord::Base)
            foreign_key = association_foreign_key model, k
            lookup_value = association_lookup_value model, k, v
            condition = { foreign_key => lookup_value }
          elsif !v.nil?
            condition = { k => v }
          end
          memo.merge! condition if condition.is_a? Hash
          memo
        end
        conditions
      end
      
      # Convert constraints that are provided as ActiveRecord::Base objects into their corresponding primary keys.
      #
      # Only works for <tt>belongs_to</tt> relationships.
      #
      # For example, :car => <#Car> might get translated into :car_id => 44 or :car_type => 44 if :foreign_key option is given.
      def association_foreign_key(model, name)
        @association_foreign_key ||= {}
        return @association_foreign_key[name] if @association_foreign_key.has_key? name
        association = model.reflect_on_association name
        raise "there is no association #{name.inspect} on #{model}" if association.nil?
        raise "can't use cohort scope on :through associations (#{self.name} #{name})" if association.options.has_key? :through
        foreign_key = association.instance_variable_get(:@options)[:foreign_key]
        if !foreign_key.blank?
          @association_foreign_key[name] = foreign_key
        else
          @association_foreign_key[name] = association.primary_key_name
        end
      end
      
      # Convert constraints that are provided as ActiveRecord::Base objects into their corresponding lookup values
      #
      # Only works for <tt>belongs_to</tt> relationships.
      #
      # For example, :car => <#Car> might get translated into :car_id => 44 or :car_id => 'JHK123' if :primary_key option is given.
      def association_lookup_value(model, name, value)
        association = model.reflect_on_association name
        primary_key = association.instance_variable_get(:@options)[:primary_key]
        if primary_key.blank?
          value.to_param
        else
          value.send primary_key
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
      { :members => count }.to_json
    end

    # sabshere 2/1/11 ActiveRecord does this for #any? but not for #none?
    def none?(&blk)
      if block_given?
        to_a.none? &blk
      else
        super
      end
    end

    def inspect
      "<Massive ActiveRecord scope with #{count} members>"
    end
  end
end
