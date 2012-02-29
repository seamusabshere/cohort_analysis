require 'arel'
require 'active_record'
require 'active_support/core_ext'

require 'cohort_analysis/strategy'
require 'cohort_analysis/strategy/big'
require 'cohort_analysis/strategy/strict'

require 'cohort_analysis/active_record_base_class_methods'
require 'cohort_analysis/active_record_relation_instance_methods'
require 'cohort_analysis/arel_visitors_visitor_instance_methods'

module CohortAnalysis
  def self.conditions_for(characteristics)
    case characteristics
    when ::Array
      characteristics.inject({}) { |memo, (k, v)| memo[k] = v; memo }
    else
      characteristics
    end
  end
end

ActiveRecord::Base.extend CohortAnalysis::ActiveRecordBaseClassMethods
ActiveRecord::Relation.send :include, CohortAnalysis::ActiveRecordRelationInstanceMethods
Arel::Visitors::Visitor.send :include, CohortAnalysis::ArelVisitorsVisitorInstanceMethods
