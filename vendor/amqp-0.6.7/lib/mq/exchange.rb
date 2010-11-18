class MQ
  # An Exchange acts as an ingress point for all published messages. An
  # exchange may also be described as a router or a matcher. Every
  # published message is received by an exchange which, depending on its
  # type (described below), determines how to deliver the message.
  #
  # It determines the next delivery hop by examining the bindings associated
  # with the exchange.
  #
  # There are three (3) supported Exchange types: direct, fanout and topic.
  #
  # As part of the standard, the server _must_ predeclare the direct exchange
  # 'amq.direct' and the fanout exchange 'amq.fanout' (all exchange names 
  # starting with 'amq.' are reserved). Attempts to declare an exchange using
  # 'amq.' as the name will raise an MQ:Error and fail. In practice these
  # default exchanges are never used directly by client code.
  #
  # These predececlared exchanges are used when the client code declares
  # an exchange without a name. In these cases the library will use
  # the default exchange for publishing the messages.
  #
  class Exchange
    include AMQP

    # Defines, intializes and returns an Exchange to act as an ingress
    # point for all published messages.
    #
    # There are three (3) supported Exchange types: direct, fanout and topic.
    #
    # As part of the standard, the server _must_ predeclare the direct exchange
    # 'amq.direct' and the fanout exchange 'amq.fanout' (all exchange names 
    # starting with 'amq.' are reserved). Attempts to declare an exchange using
    # 'amq.' as the name will raise an MQ:Error and fail. In practice these
    # default exchanges are never used directly by client code.
    #
    # == Direct
    # A direct exchange is useful for 1:1 communication between a publisher and
    # subscriber. Messages are routed to the queue with a binding that shares
    # the same name as the exchange. Alternately, the messages are routed to 
    # the bound queue that shares the same name as the routing key used for 
    # defining the exchange. This exchange type does not honor the :key option
    # when defining a new instance with a name. It _will_ honor the :key option
    # if the exchange name is the empty string. This is because an exchange
    # defined with the empty string uses the default pre-declared exchange
    # called 'amq.direct'. In this case it needs to use :key to do its matching.
    #
    #  # exchange is named 'foo'
    #  exchange = MQ::Exchange.new(MQ.new, :direct, 'foo')
    #
    #  # or, the exchange can use the default name (amq.direct) and perform
    #  # routing comparisons using the :key
    #  exchange = MQ::Exchange.new(MQ.new, :direct, "", :key => 'foo')
    #  exchange.publish('some data') # will be delivered to queue bound to 'foo'
    #
    #  queue = MQ::Queue.new(MQ.new, 'foo')
    #  # can receive data since the queue name and the exchange key match exactly
    #  queue.pop { |data| puts "received data [#{data}]" }
    #
    # == Fanout
    # A fanout exchange is useful for 1:N communication where one publisher 
    # feeds multiple subscribers. Like direct exchanges, messages published 
    # to a fanout exchange are delivered to queues whose name matches the 
    # exchange name (or are bound to that exchange name). Each queue gets 
    # its own copy of the message.
    #
    # Like the direct exchange type, this exchange type does not honor the 
    # :key option when defining a new instance with a name. It _will_ honor 
    # the :key option if the exchange name is the empty string. Fanout exchanges
    # defined with the empty string as the name use the default 'amq.fanout'.
    # In this case it needs to use :key to do its matching.
    #
    #  EM.run do
    #    clock = MQ::Exchange.new(MQ.new, :fanout, 'clock')
    #    EM.add_periodic_timer(1) do
    #      puts "\npublishing #{time = Time.now}"
    #      clock.publish(Marshal.dump(time))
    #    end
    #
    #    # one way of defining a queue
    #    amq = MQ::Queue.new(MQ.new, 'every second')
    #    amq.bind(MQ.fanout('clock')).subscribe do |time|
    #      puts "every second received #{Marshal.load(time)}"
    #    end
    #
    #    # defining a queue using the convenience method
    #    # note the string passed to #bind
    #    MQ.queue('every 5 seconds').bind('clock').subscribe do |time|
    #      time = Marshal.load(time)
    #      puts "every 5 seconds received #{time}" if time.strftime('%S').to_i%5 == 0
    #    end
    #  end
    #
    # == Topic
    # A topic exchange allows for messages to be published to an exchange 
    # tagged with a specific routing key. The Exchange uses the routing key
    # to determine which queues to deliver the message. Wildcard matching 
    # is allowed. The topic must be declared using dot notation to separate 
    # each subtopic.
    #
    # This is the only exchange type to honor the :key parameter.
    #
    # As part of the AMQP standard, each server _should_ predeclare a topic 
    # exchange called 'amq.topic' (this is not required by the standard).
    #
    # The classic example is delivering market data. When publishing market
    # data for stocks, we may subdivide the stream based on 2 
    # characteristics: nation code and trading symbol. The topic tree for 
    # Apple Computer would look like:
    #  'stock.us.aapl'
    # For a foreign stock, it may look like:
    #  'stock.de.dax'
    #
    # When publishing data to the exchange, bound queues subscribing to the
    # exchange indicate which data interests them by passing a routing key
    # for matching against the published routing key.
    #
    #  EM.run do
    #    exch = MQ::Exchange.new(MQ.new, :topic, "stocks")
    #    keys = ['stock.us.aapl', 'stock.de.dax']
    #
    #    EM.add_periodic_timer(1) do # every second
    #      puts
    #      exch.publish(10+rand(10), :routing_key => keys[rand(2)])
    #    end
    #
    #    # match against one dot-separated item
    #    MQ.queue('us stocks').bind(exch, :key => 'stock.us.*').subscribe do |price|
    #      puts "us stock price [#{price}]"
    #    end
    #
    #    # match against multiple dot-separated items
    #    MQ.queue('all stocks').bind(exch, :key => 'stock.#').subscribe do |price|
    #      puts "all stocks: price [#{price}]"
    #    end
    #
    #    # require exact match
    #    MQ.queue('only dax').bind(exch, :key => 'stock.de.dax').subscribe do |price|
    #      puts "dax price [#{price}]"
    #    end
    #  end
    #
    # For matching, the '*' (asterisk) wildcard matches against one 
    # dot-separated item only. The '#' wildcard (hash or pound symbol) 
    # matches against 0 or more dot-separated items. If none of these 
    # symbols are used, the exchange performs a comparison looking for an 
    # exact match.
    #
    # == Options
    # * :passive => true | false (default false)
    # If set, the server will not create the exchange if it does not
    # already exist. The client can use this to check whether an exchange
    # exists without modifying  the server state.
    # 
    # * :durable => true | false (default false)
    # If set when creating a new exchange, the exchange will be marked as
    # durable.  Durable exchanges remain active when a server restarts.
    # Non-durable exchanges (transient exchanges) are purged if/when a
    # server restarts. 
    #
    # A transient exchange (the default) is stored in memory-only
    # therefore it is a good choice for high-performance and low-latency
    # message publishing.
    #
    # Durable exchanges cause all messages to be written to non-volatile
    # backing store (i.e. disk) prior to routing to any bound queues.
    #
    # * :auto_delete => true | false (default false)
    # If set, the exchange is deleted when all queues have finished
    # using it. The server waits for a short period of time before
    # determining the exchange is unused to give time to the client code
    # to bind a queue to it.
    #
    # If the exchange has been previously declared, this option is ignored
    # on subsequent declarations.
    #
    # * :internal => true | false (default false)
    # If set, the exchange may not be used directly by publishers, but
    # only when bound to other exchanges. Internal exchanges are used to
    # construct wiring that is not visible to applications.
    #
    # * :nowait => true | false (default true)
    # If set, the server will not respond to the method. The client should
    # not wait for a reply method.  If the server could not complete the
    # method it will raise a channel or connection exception.
    #
    # == Exceptions
    # Doing any of these activities are illegal and will raise MQ:Error.
    # * redeclare an already-declared exchange to a different type
    # * :passive => true and the exchange does not exist (NOT_FOUND)
    #
    def initialize mq, type, name, opts = {}
      @mq = mq
      @type, @name, @opts = type, name, opts
      @mq.exchanges[@name = name] ||= self
      @key = opts[:key]
      
      unless name == "amq.#{type}" or name == '' or opts[:no_declare]
        @mq.callback{
          @mq.send Protocol::Exchange::Declare.new({ :exchange => name,
                                                     :type => type,
                                                     :nowait => true }.merge(opts))
        }
      end
    end
    attr_reader :name, :type, :key

    # This method publishes a staged file message to a specific exchange.
    # The file message will be routed to queues as defined by the exchange
    # configuration and distributed to any active consumers when the
    # transaction, if any, is committed.
    #
    #  exchange = MQ.direct('name', :key => 'foo.bar')
    #  exchange.publish("some data")
    #
    # The method takes several hash key options which modify the behavior or 
    # lifecycle of the message.
    #
    # * :routing_key => 'string'
    #
    # Specifies the routing key for the message.  The routing key is
    # used for routing messages depending on the exchange configuration.
    #
    # * :mandatory => true | false (default false)
    #
    # This flag tells the server how to react if the message cannot be
    # routed to a queue.  If this flag is set, the server will return an
    # unroutable message with a Return method.  If this flag is zero, the
    # server silently drops the message.
    #
    # * :immediate => true | false (default false)
    #
    # This flag tells the server how to react if the message cannot be
    # routed to a queue consumer immediately.  If this flag is set, the
    # server will return an undeliverable message with a Return method.
    # If this flag is zero, the server will queue the message, but with
    # no guarantee that it will ever be consumed.
    #
    #  * :persistent
    # True or False. When true, this message will remain in the queue until 
    # it is consumed (if the queue is durable). When false, the message is
    # lost if the server restarts and the queue is recreated.
    #
    # For high-performance and low-latency, set :persistent => false so the
    # message stays in memory and is never persisted to non-volatile (slow)
    # storage.
    #
    def publish data, opts = {}
      @mq.callback{
        out = []

        out << Protocol::Basic::Publish.new({ :exchange => name,
                                              :routing_key => opts[:key] || @key }.merge(opts))

        data = data.to_s

        out << Protocol::Header.new(Protocol::Basic,
                                    data.length, { :content_type => 'application/octet-stream',
                                                   :delivery_mode => (opts[:persistent] ? 2 : 1),
                                                   :priority => 0 }.merge(opts))

        out << Frame::Body.new(data)

        @mq.send *out
      }
      self
    end

    # This method deletes an exchange.  When an exchange is deleted all queue
    # bindings on the exchange are cancelled.
    #
    # Further attempts to publish messages to a deleted exchange will raise
    # an MQ::Error due to a channel close exception.
    #
    #  exchange = MQ.direct('name', :key => 'foo.bar')
    #  exchange.delete
    #
    # == Options
    # * :nowait => true | false (default true)
    # If set, the server will not respond to the method. The client should
    # not wait for a reply method.  If the server could not complete the
    # method it will raise a channel or connection exception.
    #
    #  exchange.delete(:nowait => false)
    #
    # * :if_unused => true | false (default false)
    # If set, the server will only delete the exchange if it has no queue
    # bindings. If the exchange has queue bindings the server does not
    # delete it but raises a channel exception instead (MQ:Error).
    #    
    def delete opts = {}
      @mq.callback{
        @mq.send Protocol::Exchange::Delete.new({ :exchange => name,
                                                  :nowait => true }.merge(opts))
        @mq.exchanges.delete name
      }
      nil
    end

    def reset
      @deferred_status = nil
      initialize @mq, @type, @name, @opts
    end
  end
end
