require 'dr2/types'
require 'dr2/types/string'
require 'dr2/data/message'

class Dr2::Types::Message < Dr2::Types::RW
  def self.from_dr2(io)
    io.read(1) # 'm'
    id   = Dr2::Types.read(io)
    to   = Dr2::Types.read(io)
    node = Dr2::Types.read(io, [Dr2::Types::String])

    args = []
    loop do
      begin
        args.unshift Dr2::Types.read(io)
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
    _write = proc { |x| Dr2::Types.writer(x).write_dr2(io) }

    io << "m"
    _write[@o.id]
    _write[@o.to]
    _write[@o.node]
    @o.args.reverse.each do |x|
      _write[x]
    end
    io << "."
  end
end
