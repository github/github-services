class MQ
  # Basic RPC (remote procedure call) facility.
  #
  # Needs more detail and explanation.
  #
  #  EM.run do
  #    server = MQ.rpc('hash table node', Hash)
  #
  #    client = MQ.rpc('hash table node')
  #    client[:now] = Time.now
  #    client[:one] = 1
  #
  #    client.values do |res|
  #      p 'client', :values => res
  #    end
  #
  #    client.keys do |res|
  #      p 'client', :keys => res
  #      EM.stop_event_loop
  #    end
  #  end
  #
  class RPC < BlankSlate
    # Takes a channel, queue and optional object.
    #
    # The optional object may be a class name, module name or object
    # instance. When given a class or module name, the object is instantiated
    # during this setup. The passed queue is automatically subscribed to so
    # it passes all messages (and their arguments) to the object.
    #
    # Marshalling and unmarshalling the objects is handled internally. This
    # marshalling is subject to the same restrictions as defined in the
    # Marshal[http://ruby-doc.org/core/classes/Marshal.html] standard
    # library. See that documentation for further reference.
    #
    # When the optional object is not passed, the returned rpc reference is
    # used to send messages and arguments to the queue. See #method_missing
    # which does all of the heavy lifting with the proxy. Some client
    # elsewhere must call this method *with* the optional block so that
    # there is a valid destination. Failure to do so will just enqueue
    # marshalled messages that are never consumed.
    #
    def initialize mq, queue, obj = nil
      @mq = mq
      @mq.rpcs[queue] ||= self

      if obj
        @obj = case obj
               when ::Class
                 obj.new
               when ::Module
                 (::Class.new do include(obj) end).new
               else
                 obj
               end

        @mq.queue(queue).subscribe(:ack=>true){ |info, request|
          method, *args = ::Marshal.load(request)
          ret = @obj.__send__(method, *args)

          info.ack

          if info.reply_to
            @mq.queue(info.reply_to).publish(::Marshal.dump(ret), :key => info.reply_to, :message_id => info.message_id)
          end
        }
      else
        @callbacks ||= {}
        # XXX implement and use queue(nil)
        @queue = @mq.queue(@name = "random identifier #{::Kernel.rand(999_999_999_999)}", :auto_delete => true).subscribe{|info, msg|
          if blk = @callbacks.delete(info.message_id)
            blk.call ::Marshal.load(msg)
          end
        }
        @remote = @mq.queue(queue)
      end
    end

    # Calling MQ.rpc(*args) returns a proxy object without any methods beyond
    # those in Object. All calls to the proxy are handled by #method_missing which
    # works to marshal and unmarshal all method calls and their arguments.
    #
    #  EM.run do
    #    server = MQ.rpc('hash table node', Hash)
    #    client = MQ.rpc('hash table node')
    #
    #    # calls #method_missing on #[] which marshals the method name and
    #    # arguments to publish them to the remote
    #    client[:now] = Time.now
    #    ....
    #  end
    #
    def method_missing meth, *args, &blk
      # XXX use uuids instead
      message_id = "random message id #{::Kernel.rand(999_999_999_999)}"
      @callbacks[message_id] = blk if blk
      @remote.publish(::Marshal.dump([meth, *args]), :reply_to => blk ? @name : nil, :message_id => message_id)
    end
  end
end
