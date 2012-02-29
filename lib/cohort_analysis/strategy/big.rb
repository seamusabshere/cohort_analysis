module CohortAnalysis
  class Strategy
    class Big < Strategy
      # Reduce characteristics by removing them one by one and counting the results.
      #
      # The characteristic whose removal leads to the highest record count is removed from the overall characteristic set.
      def reduce!
        @reduced_characteristics = if @reduced_characteristics.keys.length < 2
          {}
        else
          most_restrictive_characteristic = @reduced_characteristics.keys.max_by do |key|
            conditions = CohortAnalysis.conditions_for @reduced_characteristics.except(key)
            @active_record_relation.where(conditions).count
          end
          @reduced_characteristics.except most_restrictive_characteristic
        end
      end
    end
  end
end
