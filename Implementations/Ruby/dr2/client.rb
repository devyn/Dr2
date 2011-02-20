require 'dr2/types/all'
require 'socket'
require 'thread'

module Dr2
  class Client
    def initialize(host, port)
      @conn = TCPSocket.new(host, port)
      @lock = Mutex.new
      @cbks = {}
      @nmid = 0
      @thrd = _start
    end

    def call(recv, node, *args, &blk)
      @cbks[@nmid] = blk
      m = Dr2::Data::Message.new(:id   => @nmid, :to   => recv,
                                 :node => node,  :args => args)
      @lock.synchronize {
        Dr2.write(@conn, m)
      }
      @nmid += 1
      return @nmid - 1
    end

    def [](node, *args)
      r, t = nil, Thread.current
      call(nil, node, *args) do |x|
        r = x
        t.wakeup
      end
      sleep
      if r.is_a?(Exception)
        raise r
      else
        return r
      end
    end

    private

    def _start
      Thread.start do
        until @conn.closed?
          x = Dr2.read(@conn, [Dr2::Types::Response,
                               Dr2::Types::Error])
          if x.is_a?(Dr2::Data::Error)
            warn x.to_s
          else
            if @cbks.include? x.id
              Thread.start(@cbks[x.id]) { |c| c[x.value] }
              @cbks.delete x.id
            else
              @lock.synchronize {
                Dr2.write(@conn, Dr2::Data::Error.new("NotRequested",
                                                      {:id      => x.id,
                                                       :message => "I don't think I requested MID=#{x.id.inspect}."}))
              }
            end
          end
        end
      end
    end
  end
end
