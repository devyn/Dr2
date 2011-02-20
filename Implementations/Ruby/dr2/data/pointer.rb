module Dr2
  module Data
    class Pointer < Object
      attr_accessor :_client, :_proxy
      attr_reader   :_id, :_server

      ([:inspect, :=~, :to_s, :==]).each { |m|
        define_method(m){|*a|method_missing(m,*a)}
      }

      def self.new(*args)
        if defined?(Dr2::Server::Base) and
           args[0] == :random and
           args[1].is_a?(Array) and
           args[1][0].is_a?(Dr2::Server::Base)

          args[1][0].pointer_with_proxy(args[1][1]) or super(*args)
        else
          super *args
        end
      end

      def initialize(id=:random, srv_pxy_or_cli=nil)
        @_id = id
        @_id = ::Kernel.rand(2**128) if @_id == :random
        @_client, @_server, @_proxy = nil
        if defined?(::Dr2::Client) and srv_pxy_or_cli.is_a?(::Dr2::Client)
          @_client = srv_pxy_or_cli
        elsif defined?(::Dr2::Server::Base) and srv_pxy_or_cli.is_a?(::Array)
          srv_pxy = srv_pxy_or_cli
          ::Kernel.raise ::ArgumentError unless srv_pxy[0].is_a?(::Dr2::Server::Base)
          @_server, @_proxy = srv_pxy
          @_server.register self
        elsif srv_pxy_or_cli.nil?
        else
          ::Kernel.raise ::ArgumentError
        end
      end

      def _unregister!
        ::Kernel.raise ArgumentError unless @_server
        @_server.unregister self
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
          _proxycall(name, *args)
        elsif name == :inspect or name == :to_s
          # so that IRB will shut up
          "#<pointer #{@_id.inspect} -> nowhere>"
        else
          super name, *args
        end
      end

      def _proxycall(node, *args)
        if @_proxy.respond_to?(:respond_dr2)
          @_proxy.respond_dr2(node, *args)
        else
          @_proxy.send(node, *args)
        end
      end
    end
  end
end
