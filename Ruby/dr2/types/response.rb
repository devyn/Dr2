require 'dr2/types'
require 'dr2/data/response'

class Dr2::Types::Response < Dr2::Types::RW
  def self.from_dr2(io)
    io.read(1) # 'r'
    id    = Dr2::Types.read(io)
    value = Dr2::Types.read(io)
    return Dr2::Data::Response.new(id, value)
  end

  def self.might_read_dr2?(part)
    !(part =~ /^r/).nil?
  end

  def self.can_write_dr2?(obj)
    obj.is_a? Dr2::Data::Message
  end

  def write_dr2(io)
    io << "r"
    Dr2.write(io, @o.id)
    Dr2.write(io, @o.value)
  end
end
