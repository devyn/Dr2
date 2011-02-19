require 'dr2/types'

class Dr2::Types::List < Dr2::Types::RW
  def self.from_dr2(io)
    io.read(1) # 'l'
    l = []
    loop do
      begin
        l.unshift Dr2.read(io)
      rescue Dr2::Types::NoMatchException
        if $!.unexpected =~ /^\./
          return l
        else
          raise $!
        end
      end
    end
  end

  def self.might_read_dr2?(part)
    !(part =~ /^l/).nil?
  end

  def self.can_write_dr2?(obj)
    obj.is_a? Array
  end

  def write_dr2(io)
    io << "l"
    @o.reverse.each do |x|
      Dr2.write(io, x)
    end
    io << "."
  end
end
