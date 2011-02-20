require 'dr2/types'

class Dr2::Types::Dictionary < Dr2::Types::RW
  def self.from_dr2(io)
    io.read(1) # 'd'
    d = {}
    loop do
      c = true
      begin
        a = Dr2.read(io)
        c = false
        b = Dr2.read(io)
        c = true
        d[a] = b
      rescue Dr2::Types::NoMatchException
        if $!.unexpected =~ /^\./
          if c
            return d
          else
            parse_fail 'odd number of items in dictionary'
          end
        else
          raise $!
        end
      end
    end
  end

  def self.might_read_dr2?(part)
    !(part =~ /^d/).nil?
  end

  def self.can_write_dr2?(obj)
    obj.is_a? Hash
  end

  def write_dr2(io)
    io << "d"
    @o.each do |k,v|
      Dr2.write(io, k)
      Dr2.write(io, v)
    end
    io << "."
  end
end
