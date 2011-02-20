module Dr2
  module Data
    class Message
      attr_accessor :id, :to, :node, :args
      def initialize(h)
        @id   = h[:id]
        @to   = h[:to]
        @node = h[:node]
        @args = h[:args]
      end
    end
  end
end
