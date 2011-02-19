require 'dr2/util/linkio'
require 'stringio'

class Object
  def to_dr2
    Dr2::Types.writer(self).to_s
  end
end

module Dr2
  module Types
    WRITERS = []
    def self.writer(o)
      w = WRITERS.find { |w| w.can_write_dr2?(o) }
      return nil if w.nil?
      w.new(o)
    end

    class RW
      def self.inherited(c)
        Dr2::Types::READERS.unshift c
        Dr2::Types::WRITERS.unshift c
      end

      def initialize(o)
        @o = o
      end

      def to_dr2
        io = StringIO.new
        self.write_dr2(io)
        return io.string
      end

      alias to_s to_dr2
    end

    READERS = []
    def self.read(io, type=nil, &blk)
      while (b = io.read(1)) =~ /^[ \t\n]$/; end
      if type
        rs = [type]
      else
        rs = READERS.dup
      end
      # resolving potential ambiguities
      while (rs.map! { |r| [r, r.might_read_dr2?(b)]
             }.reject! { |rp| rp[1] == false };
             rs.size > 1 || rs.map { |rp| rp[1] }.include?(:maybe))
        rs.map! &:first
        b << io.read(1)
      end
      raise "in reading Dr2: unexpected #{b.inspect}" if rs.empty?
      rs.first[0].from_dr2(LinkIO.new(StringIO.new(b), io), &blk)
    end
  end
end
