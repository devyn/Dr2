require 'dr2/types'
require 'dr2/types/string'
require 'dr2/data/message'

class Dr2::Types::Message < Dr2::Types::RW
  def self.from_dr2(io)
    io.read(1) # 'm'
    id   = Dr2.read(io)
    to   = Dr2.read(io)
    node = Dr2.read(io, [Dr2::Types::String])

    args = []
    loop do
      begin
        args.unshift Dr2.read(io)
      rescue Dr2::Types::NoMatchException
        if $!.unexpected =~ /^\./
          break
        else
          raise $!
        end
      end
    end

    return Dr2::Data::Message.new(:id => id, :to => to, :node => node, :args => args)
  end

  def self.might_read_dr2?(part)
    !(part =~ /^m/).nil?
  end

  def self.can_write_dr2?(obj)
    obj.is_a? Dr2::Data::Message
  end

  def write_dr2(io)
    io << "m"
    Dr2.write(io, @o.id)
    Dr2.write(io, @o.to)
    Dr2.write(io, @o.node)

    @o.args.reverse.each do |x|
      Dr2.write(io, x)
    end
    io << "."
  end
end
