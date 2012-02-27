require 'arel'
require 'active_record'
require 'active_support/core_ext'

require 'cohort_scope/cohort'
require 'cohort_scope/big_cohort'
require 'cohort_scope/strict_cohort'

require 'cohort_scope/active_record_base_class_methods'
require 'cohort_scope/active_record_relation_instance_methods'
require 'cohort_scope/arel_visitors_visitor_instance_methods'

module CohortScope
  def self.extended(klass)
    klass.class_eval do
      class << self
        attr_accessor :minimum_cohort_size
      end
    end
  end
  
  def self.conditions_for(characteristics)
    case characteristics
    when ::Array
      characteristics.inject({}) { |memo, (k, v)| memo[k] = v; memo }
    when ::Hash
      characteristics
    end
  end
end

ActiveRecord::Base.extend CohortScope::ActiveRecordBaseClassMethods
ActiveRecord::Relation.send :include, CohortScope::ActiveRecordRelationInstanceMethods
Arel::Visitors::Visitor.send :include, CohortScope::ArelVisitorsVisitorInstanceMethods
