require 'dr2/types/all'
require 'socket'
require 'thread'

module Dr2
  module Server
    class Base
      def initialize(bind, port)
        @serv = TCPServer.new(bind, port)
        @threads = []
      end

      # Sync mode will only ever run operations synchronously, between
      # all connections,  but will have one thread  per connection. It
      # will only run one operation at a time, ever.
      def start_sync
        lock = Mutex.new
        while c = @serv.accept
          Thread.start do
            begin
              @threads << Thread.current
              loop do
                begin
                  x = Dr2::Types.read(c, [Dr2::Types::Message,
                                          Dr2::Types::Error])
                  lock.synchronize { receive x, c }
                rescue Dr2::Types::EOFException
                  break
                rescue Exception
                  Dr2::Types.writer($!).write_dr2(c)
                end
              end
            ensure
              c.close rescue nil
              @threads.delete Thread.current
            end
          end
        end
      end

      # Partial sync  mode will give  each connection its  own thread,
      # and allow  multiple connections in  parallel, but will  run no
      # more than one operation at a time per connection.
      def start_partial_sync
        while c = @serv.accept
          Thread.start do
            begin
              @threads << Thread.current
              loop do
                begin
                  x = Dr2::Types.read(c, [Dr2::Types::Message,
                                          Dr2::Types::Error])
                  receive x, c
                rescue Dr2::Types::EOFException
                  break
                rescue Exception
                  Dr2::Types.writer($!).write_dr2(c)
                end
              end
            ensure
              c.close rescue nil
              @threads.delete Thread.current
            end
          end
        end
      end

      # Async mode  will run operations and connections  each in their
      # own threads.
      def start_async
        while c = @serv.accept
          Thread.start do
            begin
              @threads << Thread.current
              l = Mutex.new
              loop do
                begin
                  x = Dr2.read(c, [Dr2::Types::Message,
                                   Dr2::Types::Error])
                  Thread.start {
                    begin
                      @threads << Thread.current
                      receive x, c, l
                    ensure
                      l.unlock rescue nil if l.locked?
                      @threads.delete Thread.current
                    end
                  }
                rescue Dr2::Types::EOFException
                  break
                rescue Dr2::Types::QuitException
                  break
                rescue Exception
                  l.synchronize { Dr2.write(c, $!) }
                end
              end
            ensure
              c.close rescue nil
              @threads.delete Thread.current
            end
          end
        end
      end

      def receive(msg_or_error, io, lock=nil)
        raise "not implemented yet"
      end

      def stop
        @threads.each(&:kill)
      end
    end
  end
end
