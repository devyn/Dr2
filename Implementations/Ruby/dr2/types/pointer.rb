require 'dr2/types'
require 'dr2/data/pointer'

class Dr2::Types::Pointer < Dr2::Types::RW
  def self.from_dr2(io)
    io.read(1) # 'p'
    return Dr2::Data::Pointer.new(Dr2.read(io))
  end

  def self.might_read_dr2?(part)
    !(part =~ /^p/).nil?
  end

  def self.can_write_dr2?(obj)
    obj.is_a? Dr2::Data::Pointer
  end

  def write_dr2(io)
    io << "p"
    Dr2.write(io, @o._id)
  end
end
