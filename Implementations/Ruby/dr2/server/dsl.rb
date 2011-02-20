require 'dr2/server/base'
require 'dr2/types/all'

module Dr2
  module Server
    # Server, DSL-style.
    class DSL < Base
      class Context
        attr_accessor :nodes, :server

        def initialize
          @nodes = {}
          @ns    = []
        end

        def node(name, &blk)
          @nodes[(@ns+[name]).join("/")] = blk
        end

        def namespace(name)
          @ns.push name
          yield
          @ns.pop
        end

        def point(x)
          Dr2::Data::Pointer.new(:random, [server, x])
        end
      end

      def initialize(bind, port, &blk)
        super bind, port
        @ctx = Context.new
        @ctx.server = self
        @ctx.instance_eval &blk
      end

      def receive(m, io, l=nil)
        if m.is_a?(Dr2::Data::Error)
          warn m.to_s
        else
          begin
            if m.to.nil?
              if n = @ctx.nodes[m.node]
                r = n[*m.args]
                l.lock if l
                begin
                  Dr2.write(io, Dr2::Data::Response.new(m.id, r))
                ensure
                  l.unlock if l
                end
              else
                raise Dr2::Data::Error.new("NodeNotFound", "node '#{m.node}' not found on #root")
              end
            elsif (x = pointer_with_id(m.to))
              r = x._proxycall(m.node, *m.args) rescue $!
              l.lock if l
              begin
                Dr2.write(io, Dr2::Data::Response.new(m.id, r))
              ensure
                l.unlock if l
              end
            else
              raise Dr2::Data::Error.new("ReceiverNotFound", "receiver ##{m.to} not found")
            end
          rescue Exception
            l.lock if l
#           warn "#{$!.class.name}: #{$!.message}\n#{$!.backtrace.join("\n").gsub(/^/, '    ')}"
            begin
              Dr2.write(io, Dr2::Data::Response.new(m.id, $!))
            ensure
              l.unlock if l
            end
          end
        end
      end
    end
  end
end
