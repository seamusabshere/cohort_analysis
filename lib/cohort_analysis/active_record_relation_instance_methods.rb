module CohortAnalysis
  module ActiveRecordRelationInstanceMethods
    # @note This doesn't return a <code>ActiveRecord::Relation</code>, so you can't just call count.
    #
    # @example Count a Flight cohort
    #   cohort = Flight.cohort(:origin => 'MSN', :dest => 'ORD')
    #   cohort.count #=> BAD! just plain Arel::SelectManager doesn't provide #count, that's an ActiveRecord::Relation thing
    #   Flight.connection.select_value(cohort.project('COUNT(*)').to_sql) #=> what you wanted
    #
    # @return [Arel::SelectManager] A select manager without any projections.
    def cohort(characteristics, options = {})
      select_manager = arel.clone
      select_manager.projections = []
      select_manager.where Strategy.create(select_manager, characteristics, options)
      select_manager
    end

    # @note Won't work properly unless it's the last constraint in your chain.
    #
    # @example Making sure it's the last thing you call
    #   Flight.cohort_relation(:origin => 'MSN', :dest => 'ORD').where(:year => 2009) #=> BAD! the cohort calculation CANNOT see :year => 2009
    #   Flight.where(:year => 2009).cohort_relation(:origin => 'MSN', :dest => 'ORD') #=> OK!
    #
    # @return [ActiveRecord::Relation]
    def cohort_relation(characteristics, options = {})
      where Strategy.create(arel, characteristics, options)
    end
  end
end

=begin
if i return ActiveRecord::Relation#where(strategy), and somebody calls #where on it, a new relation is returned that includes the strategy, but the strategy can't see the new where values

  relation = clone                                  # which keeps where_values but clears @arel
  relation.where_values += build_where(opts, rest)  # which just adds the expr
  relation

if i return Arel::SelectManager#where(strategy), it keeps the context, so the strategy can use that

  @ctx.wheres << expr
  self
=end
