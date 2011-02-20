module Dr2
  module Data
    class Response
      attr_accessor :id, :value

      def initialize(id, value)
        @id    = id
        @value = value
      end
    end
  end
end
