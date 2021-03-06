require 'dr2/types'
require 'dr2/types/string'
require 'dr2/data/error'

class Dr2::Types::Error < Dr2::Types::RW
  def self.from_dr2(io)
    io.read(1) # 'e'
    id  = Dr2.read(io, [Dr2::Types::String]) # error id
    inf = Dr2.read(io)
    return Dr2::Data::Error.new(id, inf)
  end

  def self.might_read_dr2?(part)
    !(part =~ /^e/).nil?
  end

  def self.can_write_dr2?(obj)
    obj.is_a? Exception
  end

  def write_dr2(io)
    io << "e"
    if @o.is_a? Dr2::Data::Error
      Dr2.write(io, @o.id)
      Dr2.write(io, @o.inf)
    else
      Dr2.write(io, @o.class.name)
      Dr2.write(io, @o.message)
    end
  end
end
