class MQ
  class Queue
    include AMQP
    
    # Queues store and forward messages.  Queues can be configured in the server
    # or created at runtime.  Queues must be attached to at least one exchange
    # in order to receive messages from publishers.
    #
    # Like an Exchange, queue names starting with 'amq.' are reserved for
    # internal use. Attempts to create queue names in violation of this
    # reservation will raise MQ:Error (ACCESS_REFUSED).
    #
    # When a queue is created without a name, the server will generate a 
    # unique name internally (not currently supported in this library).
    #
    # == Options
    # * :passive => true | false (default false)
    # If set, the server will not create the exchange if it does not
    # already exist. The client can use this to check whether an exchange
    # exists without modifying  the server state.
    # 
    # * :durable => true | false (default false)
    # If set when creating a new queue, the queue will be marked as
    # durable.  Durable queues remain active when a server restarts.
    # Non-durable queues (transient queues) are purged if/when a
    # server restarts.  Note that durable queues do not necessarily
    # hold persistent messages, although it does not make sense to
    # send persistent messages to a transient queue (though it is
    # allowed).
    #
    # If the queue has already been declared, any redeclaration will
    # ignore this setting. A queue may only be declared durable the
    # first time when it is created.
    #
    # * :exclusive => true | false (default false)
    # Exclusive queues may only be consumed from by the current connection.
    # Setting the 'exclusive' flag always implies 'auto-delete'. Only a
    # single consumer is allowed to remove messages from this queue.
    #
    # The default is a shared queue. Multiple clients may consume messages
    # from this queue.
    #
    # Attempting to redeclare an already-declared queue as :exclusive => true
    # will raise MQ:Error.
    #
    # * :auto_delete = true | false (default false)
    # If set, the queue is deleted when all consumers have finished
    # using it. Last consumer can be cancelled either explicitly or because
    # its channel is closed. If there was no consumer ever on the queue, it
    # won't be deleted. 
    #
    # The server waits for a short period of time before
    # determining the queue is unused to give time to the client code
    # to bind an exchange to it.
    #
    # If the queue has been previously declared, this option is ignored
    # on subsequent declarations.
    #
    # * :nowait => true | false (default true)
    # If set, the server will not respond to the method. The client should
    # not wait for a reply method.  If the server could not complete the
    # method it will raise a channel or connection exception.
    #
    def initialize mq, name, opts = {}
      @mq = mq
      @opts = opts
      @bindings ||= {}
      @mq.queues[@name = name] ||= self
      @mq.callback{
        @mq.send Protocol::Queue::Declare.new({ :queue => name,
                                                :nowait => true }.merge(opts))
      }
    end
    attr_reader :name

    # This method binds a queue to an exchange.  Until a queue is
    # bound it will not receive any messages.  In a classic messaging
    # model, store-and-forward queues are bound to a dest exchange
    # and subscription queues are bound to a dest_wild exchange.
    #
    # A valid exchange name (or reference) must be passed as the first
    # parameter. Both of these are valid:
    #  exch = MQ.direct('foo exchange')
    #  queue = MQ.queue('bar queue')
    #  queue.bind('foo.exchange') # OR
    #  queue.bind(exch)
    #
    # It is not valid to call #bind without the +exchange+ parameter.
    #
    # It is unnecessary to call #bind when the exchange name and queue
    # name match exactly (for +direct+ and +fanout+ exchanges only).
    # There is an implicit bind which will deliver the messages from
    # the exchange to the queue.
    #
    # == Options
    # * :key => 'some string'
    # Specifies the routing key for the binding.  The routing key is
    # used for routing messages depending on the exchange configuration.
    # Not all exchanges use a routing key - refer to the specific
    # exchange documentation.  If the routing key is empty and the queue
    # name is empty, the routing key will be the current queue for the
    # channel, which is the last declared queue.
    #
    # * :nowait => true | false (default true)
    # If set, the server will not respond to the method. The client should
    # not wait for a reply method.  If the server could not complete the
    # method it will raise a channel or connection exception.
    #
    def bind exchange, opts = {}
      exchange = exchange.respond_to?(:name) ? exchange.name : exchange
      @bindings[exchange] = opts

      @mq.callback{
        @mq.send Protocol::Queue::Bind.new({ :queue => name,
                                             :exchange => exchange,
                                             :routing_key => opts[:key],
                                             :nowait => true }.merge(opts))
      }
      self
    end

    # Remove the binding between the queue and exchange. The queue will
    # not receive any more messages until it is bound to another 
    # exchange.
    #
    # Due to the asynchronous nature of the protocol, it is possible for
    # "in flight" messages to be received after this call completes.
    # Those messages will be serviced by the last block used in a
    # #subscribe or #pop call.
    #
    # * :nowait => true | false (default true)
    # If set, the server will not respond to the method. The client should
    # not wait for a reply method.  If the server could not complete the
    # method it will raise a channel or connection exception.
    #
    def unbind exchange, opts = {}
      exchange = exchange.respond_to?(:name) ? exchange.name : exchange
      @bindings.delete exchange

      @mq.callback{
        @mq.send Protocol::Queue::Unbind.new({ :queue => name,
                                               :exchange => exchange,
                                               :routing_key => opts[:key],
                                               :nowait => true }.merge(opts))
      }
      self
    end

    # This method deletes a queue.  When a queue is deleted any pending
    # messages are sent to a dead-letter queue if this is defined in the
    # server configuration, and all consumers on the queue are cancelled.
    #
    # == Options
    # * :if_unused => true | false (default false)
    # If set, the server will only delete the queue if it has no
    # consumers. If the queue has consumers the server does does not
    # delete it but raises a channel exception instead.
    #
    # * :if_empty => true | false (default false)
    # If set, the server will only delete the queue if it has no
    # messages. If the queue is not empty the server raises a channel
    # exception.
    #
    # * :nowait => true | false (default true)
    # If set, the server will not respond to the method. The client should
    # not wait for a reply method.  If the server could not complete the
    # method it will raise a channel or connection exception.
    #
    def delete opts = {}
      @mq.callback{
        @mq.send Protocol::Queue::Delete.new({ :queue => name,
                                               :nowait => true }.merge(opts))
      }
      @mq.queues.delete @name
      nil
    end

    # Purge all messages from the queue.
    #
    def purge opts = {}
      @mq.callback{
        @mq.send Protocol::Queue::Purge.new({ :queue => name,
                                              :nowait => true }.merge(opts))
      }
      nil
    end

    # This method provides a direct access to the messages in a queue
    # using a synchronous dialogue that is designed for specific types of
    # application where synchronous functionality is more important than
    # performance.
    #
    # The provided block is passed a single message each time pop is called.
    #
    #  EM.run do
    #    exchange = MQ.direct("foo queue")
    #    EM.add_periodic_timer(1) do
    #      exchange.publish("random number #{rand(1000)}")
    #    end
    #    
    #    # note that #bind is never called; it is implicit because
    #    # the exchange and queue names match
    #    queue = MQ.queue('foo queue')
    #    queue.pop { |body| puts "received payload [#{body}]" }
    #
    #    EM.add_periodic_timer(1) { queue.pop }
    #  end
    #
    # If the block takes 2 parameters, both the +header+ and the +body+ will
    # be passed in for processing. The header object is defined by
    # AMQP::Protocol::Header.
    #
    #  EM.run do
    #    exchange = MQ.direct("foo queue")
    #    EM.add_periodic_timer(1) do
    #      exchange.publish("random number #{rand(1000)}")
    #    end
    #    
    #    queue = MQ.queue('foo queue')
    #    queue.pop do |header, body| 
    #      p header
    #      puts "received payload [#{body}]"
    #    end
    #
    #    EM.add_periodic_timer(1) { queue.pop }
    #  end
    #
    # == Options
    # * :ack => true | false (default false)
    # If this field is set to false the server does not expect acknowledgments
    # for messages.  That is, when a message is delivered to the client
    # the server automatically and silently acknowledges it on behalf
    # of the client.  This functionality increases performance but at
    # the cost of reliability.  Messages can get lost if a client dies
    # before it can deliver them to the application.
    #
    # * :nowait => true | false (default true)
    # If set, the server will not respond to the method. The client should
    # not wait for a reply method.  If the server could not complete the
    # method it will raise a channel or connection exception.
    #
    def pop opts = {}, &blk
      if blk
        @on_pop = blk
        @on_pop_opts = opts
      end

      @mq.callback{
        @mq.get_queue{ |q|
          q.push(self)
          @mq.send Protocol::Basic::Get.new({ :queue => name,
                                              :consumer_tag => name,
                                              :no_ack => !opts[:ack],
                                              :nowait => true }.merge(opts))
        }
      }

      self
    end

    # Subscribes to asynchronous message delivery.
    #
    # The provided block is passed a single message each time the
    # exchange matches a message to this queue.
    #
    #  EM.run do
    #    exchange = MQ.direct("foo queue")
    #    EM.add_periodic_timer(1) do
    #      exchange.publish("random number #{rand(1000)}")
    #    end
    #    
    #    queue = MQ.queue('foo queue')
    #    queue.subscribe { |body| puts "received payload [#{body}]" }
    #  end
    #
    # If the block takes 2 parameters, both the +header+ and the +body+ will
    # be passed in for processing. The header object is defined by
    # AMQP::Protocol::Header.
    #
    #  EM.run do
    #    exchange = MQ.direct("foo queue")
    #    EM.add_periodic_timer(1) do
    #      exchange.publish("random number #{rand(1000)}")
    #    end
    #    
    #    # note that #bind is never called; it is implicit because
    #    # the exchange and queue names match
    #    queue = MQ.queue('foo queue')
    #    queue.subscribe do |header, body| 
    #      p header
    #      puts "received payload [#{body}]"
    #    end
    #  end
    #
    # == Options
    # * :ack => true | false (default false)
    # If this field is set to false the server does not expect acknowledgments
    # for messages.  That is, when a message is delivered to the client
    # the server automatically and silently acknowledges it on behalf
    # of the client.  This functionality increases performance but at
    # the cost of reliability.  Messages can get lost if a client dies
    # before it can deliver them to the application.
    #
    # * :nowait => true | false (default true)
    # If set, the server will not respond to the method. The client should
    # not wait for a reply method.  If the server could not complete the
    # method it will raise a channel or connection exception.
    #
    # * :confirm => proc (default nil)
    # If set, this proc will be called when the server confirms subscription
    # to the queue with a ConsumeOk message. Setting this option will
    # automatically set :nowait => false. This is required for the server
    # to send a confirmation.
    #
    def subscribe opts = {}, &blk
      @consumer_tag = "#{name}-#{Kernel.rand(999_999_999_999)}"
      @mq.consumers[@consumer_tag] = self

      raise Error, 'already subscribed to the queue' if subscribed?

      @on_msg = blk
      @on_msg_opts = opts
      opts[:nowait] = false if (@on_confirm_subscribe = opts[:confirm])

      @mq.callback{
        @mq.send Protocol::Basic::Consume.new({ :queue => name,
                                                :consumer_tag => @consumer_tag,
                                                :no_ack => !opts[:ack],
                                                :nowait => true }.merge(opts))
      }
      self
    end

    # Removes the subscription from the queue and cancels the consumer.
    # New messages will not be received by the queue. This call is similar
    # in result to calling #unbind.
    #
    # Due to the asynchronous nature of the protocol, it is possible for
    # "in flight" messages to be received after this call completes.
    # Those messages will be serviced by the last block used in a
    # #subscribe or #pop call.
    #
    # Additionally, if the queue was created with _autodelete_ set to 
    # true, the server will delete the queue after its wait period
    # has expired unless the queue is bound to an active exchange.
    #
    # The method accepts a block which will be executed when the 
    # unsubscription request is acknowledged as complete by the server.
    #
    # * :nowait => true | false (default true)
    # If set, the server will not respond to the method. The client should
    # not wait for a reply method.  If the server could not complete the
    # method it will raise a channel or connection exception.
    #
    def unsubscribe opts = {}, &blk
      @on_cancel = blk
      @mq.callback{
        @mq.send Protocol::Basic::Cancel.new({ :consumer_tag => @consumer_tag }.merge(opts))
      }
      self
    end

    def publish data, opts = {}
      exchange.publish(data, opts)
    end
    
    # Boolean check to see if the current queue has already been subscribed
    # to an exchange. 
    #
    # Attempts to #subscribe multiple times to any exchange will raise an
    # Exception. Only a single block at a time can be associated with any 
    # one queue for processing incoming messages.
    #
    def subscribed?
      !!@on_msg
    end

    # Passes the message to the block passed to pop or subscribe. 
    #
    # Performs an arity check on the block's parameters. If arity == 1, 
    # pass only the message body. If arity != 1, pass the headers and
    # the body to the block.
    #
    # See AMQP::Protocol::Header for the hash properties available from
    # the headers parameter. See #pop or #subscribe for a code example.
    #
    def receive headers, body
      headers = MQ::Header.new(@mq, headers)

      if cb = (@on_msg || @on_pop)
        cb.call *(cb.arity == 1 ? [body] : [headers, body])
      end
    end

    # Get the number of messages and consumers on a queue.
    #
    #  MQ.queue('name').status{ |num_messages, num_consumers|
    #   puts num_messages
    #  }
    #
    def status opts = {}, &blk
      @on_status = blk
      @mq.callback{
        @mq.send Protocol::Queue::Declare.new({ :queue => name,
                                                :passive => true }.merge(opts))
      }
      self
    end

    def receive_status declare_ok
      if @on_status
        m, c = declare_ok.message_count, declare_ok.consumer_count
        @on_status.call *(@on_status.arity == 1 ? [m] : [m, c])
        @on_status = nil
      end
    end

    def confirm_subscribe
      @on_confirm_subscribe.call if @on_confirm_subscribe
      @on_confirm_subscribe = nil
    end

    def cancelled
      @on_cancel.call if @on_cancel
      @on_cancel = @on_msg = nil
      @mq.consumers.delete @consumer_tag
      @consumer_tag = nil
    end

    def reset
      @deferred_status = nil
      initialize @mq, @name, @opts

      binds = @bindings
      @bindings = {}
      binds.each{|ex,opts| bind(ex, opts) }

      if blk = @on_msg
        @on_msg = nil
        subscribe @on_msg_opts, &blk
      end

      if @on_pop
        pop @on_pop_opts, &@on_pop
      end
    end
  
    private
    
    def exchange
      @exchange ||= Exchange.new(@mq, :direct, '', :key => name)
    end
  end
end