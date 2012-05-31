module CohortAnalysis
  class Strategy
    class Strict < Strategy
      attr_reader :reverse_priority
      
      def initialize(select_manager, characteristics, options = {})
        super
        if priority = options[:priority]
          @reverse_priority = priority.reverse
        elsif ::RUBY_VERSION < '1.9' and not characteristics.is_a?(::ActiveSupport::OrderedHash)
          raise ::ArgumentError, "[cohort_analysis] Since Ruby 1.8 hashes are not ordered, please use :priority => [...] or pass characteristics as an ActiveSupport::OrderedHash (not recommended)"
        end
      end

      # Reduce characteristics by removing the least important one.
      def reduce!
        least_important_key = if reverse_priority
          reverse_priority.detect do |k|
            current.has_key? k
          end
        else
          current.keys.last
        end
        if least_important_key
          current.delete least_important_key
        else
          raise ::RuntimeError, "[cohort_analysis] Priority improperly specified"
        end
      end
    end
  end
end
