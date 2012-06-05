module CohortAnalysis
  class Strategy
    class Big < Strategy
      # Reduce characteristics by removing them one by one and counting the results.
      #
      # The characteristic whose removal leads to the highest record count is removed from the overall characteristic set.
      def reduce!
        @current = if current.keys.length < 2
          {}
        else
          most_restrictive = current.keys.max_by do |k|
            count current.except(k)
          end
          current.except most_restrictive
        end
      end
    end
  end
end
