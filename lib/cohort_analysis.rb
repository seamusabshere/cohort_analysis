require 'arel'
require 'active_support/core_ext'

require 'cohort_analysis/strategy'
require 'cohort_analysis/strategy/big'
require 'cohort_analysis/strategy/strict'

module CohortAnalysis
end

require 'cohort_analysis/arel_select_manager_instance_methods'
Arel::SelectManager.send :include, CohortAnalysis::ArelSelectManagerInstanceMethods

require 'cohort_analysis/arel_table_instance_methods'
Arel::Table.send :include, CohortAnalysis::ArelTableInstanceMethods

require 'cohort_analysis/arel_visitors_visitor_instance_methods'
Arel::Visitors::Visitor.send :include, CohortAnalysis::ArelVisitorsVisitorInstanceMethods

if defined?(ActiveRecord)
  require 'cohort_analysis/active_record_base_class_methods'
  ActiveRecord::Base.extend CohortAnalysis::ActiveRecordBaseClassMethods

  require 'cohort_analysis/active_record_relation_instance_methods'
  ActiveRecord::Relation.send :include, CohortAnalysis::ActiveRecordRelationInstanceMethods
end
