require 'dr2/types'

class Dr2::Types::Integer < Dr2::Types::RW
  def self.from_dr2(io)
    io.read(1) # 'i'
    s = io.gets('.').chomp('.')
    parse_fail "string not hexadecimal!" unless s =~ /^[ \t\r\n]*(\-?[0-9A-Fa-f \t\r\n]+)[ \t\r\n]*$/
    $1.gsub(/[ \t\r\n]/, '').to_i(16)
  end

  def self.might_read_dr2?(part)
    !(part =~ /^i([0-9A-Fa-f \t\r\n]+(\.)?)?/).nil?
  end

  def self.can_write_dr2?(obj)
    obj.is_a? Integer
  end

  def write_dr2(io)
    io << "i" << @o.to_s(16) << "."
  end
end
