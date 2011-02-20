require 'dr2/util/linkio'
require 'stringio'

class Object
  def to_dr2
    Dr2::Types.writer(self).to_s
  end
end

module Dr2
  module Types
    class ParseException < Exception
    end
    class EOFException < ParseException
      def initialize
      end

      def to_s
        "reached EOF prematurely"
      end
    end
    class NoMatchException < ParseException
      attr_reader :unexpected

      def initialize(u)
        @unexpected = u
      end

      def to_s
        return "no match - unexpected #@unexpected"
      end
    end

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

      private

      def self.parse_fail(s)
        raise Dr2::Types::ParseException, s
      end
    end

    READERS = []
    def self.read(io, types=nil, &blk)
      while (b = io.read(1)) =~ /^[ \t\n]$/; end
      raise Dr2::Types::EOFException if b.nil? and (io.eof? rescue io.closed?)
      raise Dr2::Types::NoMatchException, b if b == "."
      if types
        rs = types.dup
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
      raise Dr2::Types::NoMatchException, b if rs.empty?
      rs.first[0].from_dr2(LinkIO.new(StringIO.new(b), io), &blk)
    end
  end

  # shortcuts

  def self.read(*args, &blk)
    Dr2::Types.read(*args, &blk)
  end

  def self.write(io, obj)
    Dr2::Types.writer(obj).write_dr2(io)
  end

  def self.load(str)
    Dr2::Types.read(StringIO.new(str))
  end

  def self.dump(obj)
    Dr2::Types.writer(obj).to_s
  end
end
