require 'dr2/types'

class Dr2::Types::String < Dr2::Types::RW
  @@bufsize = 4096 # 4kB; if more/less is wanted, just set it.

  def self.bufsize=(b)
    @@bufsize = b
  end

  def self.from_dr2(io)
    io.read(1) # 's'
    len = io.gets(":").chomp(":").to_i(16)
    if block_given?
      # Buffered mode. Useful for writing to a file. Use like:
      #
      #   File.open('output.txt', 'w') do |file|
      #     Dr2::Types.read(sock, Dr2::Types::String) do |part|
      #       file.write part
      #     end
      #   end
      rem = len
      b = ""
      while rem > @@bufsize
        io.read(@@bufsize, b)
        raise Dr2::Types::EOFException if b.length < @@bufsize and io.eof?
        yield b
      end
      if rem > 0
        io.read(rem, b)
        raise Dr2::Types::EOFException if b.length < rem and io.eof?
        yield b
      end
    else
      # String  mode.  Don't use  with  anything  huge, because  it'll
      # probably use a ton of memory.
      s = io.read(len)
      raise Dr2::Types::EOFException if s.length < len and io.eof?
      return s
    end
  end

  def self.might_read_dr2?(part)
    !(part =~ /^s([0-9A-Fa-f](\:.*)?)?/).nil?
  end

  def self.can_write_dr2?(obj)
    obj.is_a?(String) || obj.is_a?(Symbol)
  end

  def write_dr2(io)
    io << "s" << @o.length.to_s(16) << ":" << @o.to_s
  end
end
