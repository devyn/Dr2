require 'dr2/types'

class Dr2::Types::Null < Dr2::Types::RW
  def self.read_dr2(io)
    io.read(1)
    return nil
  end

  def self.might_read_dr2?(part)
    !(part =~ /^n$/).nil?
  end

  def self.can_write_dr2?(obj)
    obj.nil?
  end

  def write_dr2(io)
    io << "n"
  end
end
