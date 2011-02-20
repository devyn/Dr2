module Dr2
  module Data
    class Pointer < BasicObject
      attr_accessor :_client, :_proxy
      attr_reader   :_id, :_server

      def initialize(id=:random, srv_pxy_or_cli=nil)
        @_id = id
        @_id = rand(2**128) if @_id == :random
        if defined?(::Dr2::Client) and srv_pxy_or_cli.is_a?(::Dr2::Client)
          @_client = srv_pxy_or_cli
        elsif defined?(::Dr2::Server::Base) and srv_pxy_or_cli.is_a?(::Array)
          srv_pxy = srv_pxy_or_cli
          ::Kernel.raise ::ArgumentError unless srv_pxy[0].is_a?(::Dr2::Server::Base)
          @_server, @_proxy = srv_pxy
          @_server.register @_id, self
        elsif srv_pxy_or_cli.nil?
        else
          ::Kernel.raise ::ArgumentError
        end
      end

      def _unregister!
        raise ArgumentError unless @_server
        @_server.unregister @_id
      end

      def method_missing(name, *args)
        if @_client
          r = nil
          t = ::Thread.current
          @_client.call(@_id, name, *args) do |x|
            r = x
            t.wakeup
          end
          sleep
          if r.is_a?(Dr2::Data::Error)
            ::Kernel.raise(r)
          else
            return r
          end
        elsif @_server and @_proxy
          @proxy.send(name, *args)
        elsif name == :inspect or name == :to_s
          # so that IRB will shut up
          "#<pointer #{@_id.inspect} -> nowhere>"
        else
          super name, *args
        end
      end
    end
  end
end
