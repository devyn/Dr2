# For reading from multiple IOs as if they were one.
class LinkIO
  def initialize(*ios)
    @pas = []
    @ios = ios
    @cur = @ios.shift
  end

  def read(len=nil)
    if len.nil?
      ([@cur] + @ios).map{|i|i.read}.join
    else
      a = @cur.read(len)
      if !@ios.empty? and a.length < len
        shift_io!
        a + read(len - a.length)
      else
        return a
      end
    end
  end

  def gets(sep=nil)
    a = @cur.gets(sep)
    if !@ios.empty? and !(a =~ /#{Regexp.escape(sep||$/)}$/)
      shift_io!
      a + gets(sep)
    else
      return a
    end
  end

  def pos
    (@pas + [@cur] + @ios).inject(0) {|o,x| o + x.pos }
  end

  def length
    (@pas + [@cur] + @ios).inject(0) {|o,x| o + x.length }
  end

  private

  def shift_io!
    @pas << @cur
    @cur = @ios.shift
  end
end
