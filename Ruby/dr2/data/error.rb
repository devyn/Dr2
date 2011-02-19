module Dr2
  module Data
    class Error < Exception
      def initialize(id, inf)
        @id  = id
        @inf = inf
      end

      def to_s
        "#@id: #{@inf.is_a?(Hash) ? @inf['message'] : @inf}"
      end
    end
  end
end
