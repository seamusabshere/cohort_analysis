require 'active_record'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/module/delegation
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3

module ActiveRecord
  class Relation
    def inspect_count_only!
      @inspect_count_only = true
    end
    def inspect_count_only?
      @inspect_count_only == true
    end
    def as_json(*)
      inspect_count_only? ? { :members => count } : super
    end
    def inspect
      inspect_count_only? ? "<Massive ActiveRecord scope with #{count} members>" : super
    end
  end
end

module CohortScope
  def self.extended(klass)
    klass.cattr_accessor :minimum_cohort_size, :instance_writer => false
  end

  # Find the biggest scope possible by removing constraints <b>in any order</b>.
  # Returns an empty scope if it can't meet the minimum scope size.
  def big_cohort(constraints = {}, custom_minimum_cohort_size = nil)
    raise ArgumentError, "You can't give a big_cohort an OrderedHash; do you want strict_cohort?" if constraints.is_a?(ActiveSupport::OrderedHash)
    _cohort_scope constraints, custom_minimum_cohort_size
  end

  # Find the first acceptable scope by removing constraints <b>in strict order</b>, starting with the last constraint.
  # Returns an empty scope if it can't meet the minimum scope size.
  #
  # <tt>constraints</tt> must be an <tt>ActiveSupport::OrderedHash</tt> (no support for ruby 1.9's natively ordered hashes yet).
  #
  # Note that the first constraint is implicitly required.
  #
  # Take this example, where favorite color is considered to be "more important" than birthdate:
  #
  #   ordered_constraints = ActiveSupport::OrderedHash.new
  #   ordered_constraints[:favorite_color] = 'heliotrope'
  #   ordered_constraints[:birthdate] = '1999-01-01'
  #   Citizen.strict_cohort(ordered_constraints) #=> [...]
  #
  # If the original constraints don't meet the minimum scope size, then the only constraint that can be removed is birthdate.
  # In other words, this would never return a scope that was constrained on birthdate but not on favorite_color.
  def strict_cohort(constraints, custom_minimum_cohort_size = nil)
    raise ArgumentError, "You need to give strict_cohort an OrderedHash" unless constraints.is_a?(ActiveSupport::OrderedHash)
    _cohort_scope constraints, custom_minimum_cohort_size
  end

  protected

  # Recursively look for a scope that meets the constraints and is at least <tt>minimum_cohort_size</tt>.
  def _cohort_scope(constraints, custom_minimum_cohort_size)
    raise RuntimeError, "You need to set #{name}.minimum_cohort_size = X" unless minimum_cohort_size.present?
    
    if constraints.values.none? # failing base case
      return scoped.where('false')
    end
    
    this_hash = _cohort_constraints constraints
    this_count = scoped.where(this_hash).count
    
    if this_count >= (custom_minimum_cohort_size || minimum_cohort_size) # successful base case
      cohort = scoped.where this_hash
    else
      cohort = _cohort_scope _cohort_reduce_constraints(constraints), custom_minimum_cohort_size
    end
    cohort.inspect_count_only!
    cohort
  end
  
  # Sanitize constraints by
  # * removing nil constraints (so constraints like "X IS NULL" are impossible, sorry)
  # * converting ActiveRecord::Base objects into integer foreign key constraints
  def _cohort_constraints(constraints)
    new_hash = constraints.is_a?(ActiveSupport::OrderedHash) ? ActiveSupport::OrderedHash.new : Hash.new
    conditions = constraints.inject(new_hash) do |memo, tuple|
      k, v = tuple
      if v.kind_of?(ActiveRecord::Base)
        condition = { _cohort_association_primary_key(k) => v.to_param }
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
  def _cohort_association_primary_key(name)
    @_cohort_association_primary_keys ||= {}
    return @_cohort_association_primary_keys[name] if @_cohort_association_primary_keys.has_key? name
    a = reflect_on_association name
    raise "can't use cohort scope on :through associations (#{self.name} #{name})" if a.options.has_key? :through
    if !a.primary_key_name.blank?
      @_cohort_association_primary_keys[name] = a.primary_key_name
    else
      raise "we need some other way to find primary key"
    end
  end
  
  # Choose how to reduce constraints based on whether we're looking for a big cohort or a strict cohort.
  def _cohort_reduce_constraints(constraints)
    case constraints
    when ActiveSupport::OrderedHash
      _cohort_reduce_constraints_in_order constraints
    when Hash
      _cohort_reduce_constraints_seeking_maximum_count constraints
    else
      raise "what did you pass me? #{constraints}"
    end
  end
  
  # (Used by <tt>big_cohort</tt>)
  #
  # Reduce constraints by removing them one by one and counting the results.
  #
  # The constraint whose removal leads to the highest record count is removed from the overall constraint set.
  def _cohort_reduce_constraints_seeking_maximum_count(constraints)
    highest_count_after_removal = nil
    losing_key = nil
    constraints.keys.each do |key|
      test_constraints = constraints.except(key)
      count_after_removal = scoped.where(_cohort_constraints(test_constraints)).count
      if highest_count_after_removal.nil? or count_after_removal > highest_count_after_removal
        highest_count_after_removal = count_after_removal
        losing_key = key
      end
    end
    constraints.except losing_key
  end

  # (Used by <tt>strict_cohort</tt>)
  #
  # Reduce constraints by removing the least important one.
  def _cohort_reduce_constraints_in_order(constraints)
    reduced_constraints = constraints.dup
    reduced_constraints.delete constraints.keys.last
    reduced_constraints
  end
end
