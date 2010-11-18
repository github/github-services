#:main: README
#

$:.unshift File.expand_path(File.dirname(File.expand_path(__FILE__)))
require 'amqp'

class MQ
  %w[ exchange queue rpc header ].each do |file|
    require "mq/#{file}"
  end

  class << self
    @logging = false
    attr_accessor :logging
  end

  # Raised whenever an illegal operation is attempted.
  class Error < StandardError; end
end

# The top-level class for building AMQP clients. This class contains several
# convenience methods for working with queues and exchanges. Many calls
# delegate/forward to subclasses, but this is the preferred API. The subclass
# API is subject to change while this high-level API will likely remain
# unchanged as the library evolves. All code examples will be written using
# the MQ API.
#
# Below is a somewhat complex example that demonstrates several capabilities
# of the library. The example starts a clock using a +fanout+ exchange which
# is used for 1 to many communications. Each consumer generates a queue to
# receive messages and do some operation (in this case, print the time).
# One consumer prints messages every second while the second consumer prints
# messages every 2 seconds. After 5 seconds has elapsed, the 1 second
# consumer is deleted.
# 
# Of interest is the relationship of EventMachine to the process. All MQ
# operations must occur within the context of an EM.run block. We start
# EventMachine in its own thread with an empty block; all subsequent calls
# to the MQ API add their blocks to the EM.run block. This demonstrates how
# the library could be used to build up and tear down communications outside
# the context of an EventMachine block and/or integrate the library with
# other synchronous operations. See the EventMachine documentation for
# more information.
#
#   require 'rubygems'
#   require 'mq'
#  
#   thr = Thread.new { EM.run }
#  
#   # turns on extreme logging
#   #AMQP.logging = true
#  
#   def log *args
#     p args
#   end
#  
#   def publisher
#     clock = MQ.fanout('clock')
#     EM.add_periodic_timer(1) do
#       puts
#  
#       log :publishing, time = Time.now
#       clock.publish(Marshal.dump(time))
#     end
#   end
#  
#   def one_second_consumer
#     MQ.queue('every second').bind(MQ.fanout('clock')).subscribe do |time|
#       log 'every second', :received, Marshal.load(time)
#     end
#   end
#  
#   def two_second_consumer
#     MQ.queue('every 2 seconds').bind('clock').subscribe do |time|
#       time = Marshal.load(time)
#       log 'every 2 seconds', :received, time if time.sec % 2 == 0
#     end
#   end
#  
#   def delete_one_second
#     EM.add_timer(5) do
#       # delete the 'every second' queue
#       log 'Deleting [every second] queue'
#       MQ.queue('every second').delete
#     end
#   end
#  
#   publisher
#   one_second_consumer
#   two_second_consumer
#   delete_one_second
#   thr.join
#  
#  __END__
#  
#  [:publishing, Tue Jan 06 22:46:14 -0600 2009]
#  ["every second", :received, Tue Jan 06 22:46:14 -0600 2009]
#  ["every 2 seconds", :received, Tue Jan 06 22:46:14 -0600 2009]
#  
#  [:publishing, Tue Jan 06 22:46:16 -0600 2009]
#  ["every second", :received, Tue Jan 06 22:46:16 -0600 2009]
#  ["every 2 seconds", :received, Tue Jan 06 22:46:16 -0600 2009]
#  
#  [:publishing, Tue Jan 06 22:46:17 -0600 2009]
#  ["every second", :received, Tue Jan 06 22:46:17 -0600 2009]
#  
#  [:publishing, Tue Jan 06 22:46:18 -0600 2009]
#  ["every second", :received, Tue Jan 06 22:46:18 -0600 2009]
#  ["every 2 seconds", :received, Tue Jan 06 22:46:18 -0600 2009]
#  ["Deleting [every second] queue"]
#  
#  [:publishing, Tue Jan 06 22:46:19 -0600 2009]
#  
#  [:publishing, Tue Jan 06 22:46:20 -0600 2009]
#  ["every 2 seconds", :received, Tue Jan 06 22:46:20 -0600 2009]
#
class MQ
  include AMQP
  include EM::Deferrable

  # Returns a new channel. A channel is a bidirectional virtual
  # connection between the client and the AMQP server. Elsewhere in the
  # library the channel is referred to in parameter lists as +mq+.
  #
  # Optionally takes the result from calling AMQP::connect.
  #
  # Rarely called directly by client code. This is implicitly called
  # by most instance methods. See #method_missing.
  #
  #  EM.run do
  #    channel = MQ.new
  #  end
  #
  #  EM.run do
  #    channel = MQ.new AMQP::connect
  #  end
  #
  def initialize connection = nil
    raise 'MQ can only be used from within EM.run{}' unless EM.reactor_running?

    @connection = connection || AMQP.start

    conn.callback{ |c|
      @channel = c.add_channel(self)
      send Protocol::Channel::Open.new
    }
  end
  attr_reader :channel, :connection
  
  # May raise a MQ::Error exception when the frame payload contains a
  # Protocol::Channel::Close object. 
  #
  # This usually occurs when a client attempts to perform an illegal
  # operation. A short, and incomplete, list of potential illegal operations
  # follows:
  # * publish a message to a deleted exchange (NOT_FOUND)
  # * declare an exchange using the reserved 'amq.' naming structure (ACCESS_REFUSED)
  #
  def process_frame frame
    log :received, frame

    case frame
    when Frame::Header
      @header = frame.payload
      @body = ''

    when Frame::Body
      @body << frame.payload
      if @body.length >= @header.size
        @header.properties.update(@method.arguments)
        @consumer.receive @header, @body if @consumer
        @body = @header = @consumer = @method = nil
      end

    when Frame::Method
      case method = frame.payload
      when Protocol::Channel::OpenOk
        send Protocol::Access::Request.new(:realm => '/data',
                                           :read => true,
                                           :write => true,
                                           :active => true,
                                           :passive => true)

      when Protocol::Access::RequestOk
        @ticket = method.ticket
        callback{
          send Protocol::Channel::Close.new(:reply_code => 200,
                                            :reply_text => 'bye',
                                            :method_id => 0,
                                            :class_id => 0)
        } if @closing
        succeed

      when Protocol::Basic::CancelOk
        if @consumer = consumers[ method.consumer_tag ]
          @consumer.cancelled
        else
          MQ.error "Basic.CancelOk for invalid consumer tag: #{method.consumer_tag}"
        end

      when Protocol::Queue::DeclareOk
        queues[ method.queue ].receive_status method

      when Protocol::Basic::Deliver, Protocol::Basic::GetOk
        @method = method
        @header = nil
        @body = ''

        if method.is_a? Protocol::Basic::GetOk
          @consumer = get_queue{|q| q.shift }
          MQ.error "No pending Basic.GetOk requests" unless @consumer
        else
          @consumer = consumers[ method.consumer_tag ]
          MQ.error "Basic.Deliver for invalid consumer tag: #{method.consumer_tag}" unless @consumer
        end

      when Protocol::Basic::GetEmpty
        if @consumer = get_queue{|q| q.shift }
          @consumer.receive nil, nil
        else
          MQ.error "Basic.GetEmpty for invalid consumer"
        end

      when Protocol::Channel::Close
        raise Error, "#{method.reply_text} in #{Protocol.classes[method.class_id].methods[method.method_id]} on #{@channel}"

      when Protocol::Channel::CloseOk
        @closing = false
        conn.callback{ |c|
          c.channels.delete @channel
          c.close if c.channels.empty?
        }

      when Protocol::Basic::ConsumeOk
        if @consumer = consumers[ method.consumer_tag ]
          @consumer.confirm_subscribe
        else
          MQ.error "Basic.ConsumeOk for invalid consumer tag: #{method.consumer_tag}"
        end
      end
    end
  end

  def send *args
    conn.callback{ |c|
      (@_send_mutex ||= Mutex.new).synchronize do
        args.each do |data|
          data.ticket = @ticket if @ticket and data.respond_to? :ticket=
          log :sending, data
          c.send data, :channel => @channel
        end
      end
    }
  end

  # Defines, intializes and returns an Exchange to act as an ingress
  # point for all published messages.
  #
  # == Direct
  # A direct exchange is useful for 1:1 communication between a publisher and
  # subscriber. Messages are routed to the queue with a binding that shares
  # the same name as the exchange. Alternately, the messages are routed to 
  # the bound queue that shares the same name as the routing key used for 
  # defining the exchange. This exchange type does not honor the +:key+ option
  # when defining a new instance with a name. It _will_ honor the +:key+ option
  # if the exchange name is the empty string.
  # Allocating this exchange without a name _or_ with the empty string
  # will use the internal 'amq.direct' exchange.
  #
  # Any published message, regardless of its persistence setting, is thrown
  # away by the exchange when there are no queues bound to it.
  #
  #  # exchange is named 'foo'
  #  exchange = MQ.direct('foo')
  #
  #  # or, the exchange can use the default name (amq.direct) and perform
  #  # routing comparisons using the :key
  #  exchange = MQ.direct("", :key => 'foo')
  #  exchange.publish('some data') # will be delivered to queue bound to 'foo'
  #
  #  queue = MQ.queue('foo')
  #  # can receive data since the queue name and the exchange key match exactly
  #  queue.pop { |data| puts "received data [#{data}]" }
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
  # A transient exchange (the default) is stored in memory-only. The
  # exchange and all bindings will be lost on a server restart.
  # It makes no sense to publish a persistent message to a transient
  # exchange.
  #
  # Durable exchanges and their bindings are recreated upon a server 
  # restart. Any published messages not routed to a bound queue are lost.
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
  def direct name = 'amq.direct', opts = {}
    exchanges[name] ||= Exchange.new(self, :direct, name, opts)
  end

  # Defines, intializes and returns an Exchange to act as an ingress
  # point for all published messages.
  #
  # == Fanout
  # A fanout exchange is useful for 1:N communication where one publisher 
  # feeds multiple subscribers. Like direct exchanges, messages published 
  # to a fanout exchange are delivered to queues whose name matches the 
  # exchange name (or are bound to that exchange name). Each queue gets 
  # its own copy of the message.
  #
  # Any published message, regardless of its persistence setting, is thrown
  # away by the exchange when there are no queues bound to it.
  #
  # Like the direct exchange type, this exchange type does not honor the 
  # +:key+ option when defining a new instance with a name. It _will_ honor 
  # the +:key+ option if the exchange name is the empty string.
  # Allocating this exchange without a name _or_ with the empty string
  # will use the internal 'amq.fanout' exchange.
  #
  #  EM.run do
  #    clock = MQ.fanout('clock')
  #    EM.add_periodic_timer(1) do
  #      puts "\npublishing #{time = Time.now}"
  #      clock.publish(Marshal.dump(time))
  #    end
  #
  #    amq = MQ.queue('every second')
  #    amq.bind(MQ.fanout('clock')).subscribe do |time|
  #      puts "every second received #{Marshal.load(time)}"
  #    end
  #
  #    # note the string passed to #bind
  #    MQ.queue('every 5 seconds').bind('clock').subscribe do |time|
  #      time = Marshal.load(time)
  #      puts "every 5 seconds received #{time}" if time.strftime('%S').to_i%5 == 0
  #    end
  #  end
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
  # A transient exchange (the default) is stored in memory-only. The
  # exchange and all bindings will be lost on a server restart.
  # It makes no sense to publish a persistent message to a transient
  # exchange.
  #
  # Durable exchanges and their bindings are recreated upon a server 
  # restart. Any published messages not routed to a bound queue are lost.
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
  def fanout name = 'amq.fanout', opts = {}
    exchanges[name] ||= Exchange.new(self, :fanout, name, opts)
  end

  # Defines, intializes and returns an Exchange to act as an ingress
  # point for all published messages.
  #
  # == Topic
  # A topic exchange allows for messages to be published to an exchange 
  # tagged with a specific routing key. The Exchange uses the routing key
  # to determine which queues to deliver the message. Wildcard matching 
  # is allowed. The topic must be declared using dot notation to separate 
  # each subtopic.
  #
  # This is the only exchange type to honor the +key+ hash key for all
  # cases.
  #
  # Any published message, regardless of its persistence setting, is thrown
  # away by the exchange when there are no queues bound to it.
  #
  # As part of the AMQP standard, each server _should_ predeclare a topic 
  # exchange called 'amq.topic' (this is not required by the standard).
  # Allocating this exchange without a name _or_ with the empty string
  # will use the internal 'amq.topic' exchange.
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
  #    exch = MQ.topic("stocks")
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
  # A transient exchange (the default) is stored in memory-only. The
  # exchange and all bindings will be lost on a server restart.
  # It makes no sense to publish a persistent message to a transient
  # exchange.
  #
  # Durable exchanges and their bindings are recreated upon a server 
  # restart. Any published messages not routed to a bound queue are lost.
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
  def topic name = 'amq.topic', opts = {}
    exchanges[name] ||= Exchange.new(self, :topic, name, opts)
  end

  # Defines, intializes and returns an Exchange to act as an ingress
  # point for all published messages.
  #
  # == Headers
  # A headers exchange allows for messages to be published to an exchange 
  #
  # Any published message, regardless of its persistence setting, is thrown
  # away by the exchange when there are no queues bound to it.
  #
  # As part of the AMQP standard, each server _should_ predeclare a headers 
  # exchange called 'amq.match' (this is not required by the standard).
  # Allocating this exchange without a name _or_ with the empty string
  # will use the internal 'amq.match' exchange.
  #
  # TODO: The classic example is ... 
  #
  # When publishing data to the exchange, bound queues subscribing to the
  # exchange indicate which data interests them by passing arguments
  # for matching against the headers in published messages. The
  # form of the matching can be controlled by the 'x-match' argument, which
  # may be 'any' or 'all'. If unspecified (in RabbitMQ at least), it defaults
  # to "all".
  #
  # A value of 'all' for 'x-match' implies that all values must match (i.e. 
  # it does an AND of the headers ), while a value of 'any' implies that 
  # at least one should match (ie. it does an OR).
  #
  # TODO: document behavior when either the binding or the message is missing
  #       a header present in the other
  #
  # TODO: insert example
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
  # A transient exchange (the default) is stored in memory-only. The
  # exchange and all bindings will be lost on a server restart.
  # It makes no sense to publish a persistent message to a transient
  # exchange.
  #
  # Durable exchanges and their bindings are recreated upon a server 
  # restart. Any published messages not routed to a bound queue are lost.
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
  # * using a value other than "any" or "all" for "x-match"
  def headers name = 'amq.match', opts = {}
    exchanges[name] ||= Exchange.new(self, :headers, name, opts)
  end

  # Queues store and forward messages.  Queues can be configured in the server
  # or created at runtime.  Queues must be attached to at least one exchange
  # in order to receive messages from publishers.
  #
  # Like an Exchange, queue names starting with 'amq.' are reserved for
  # internal use. Attempts to create queue names in violation of this
  # reservation will raise MQ:Error (ACCESS_REFUSED).
  #
  # It is not supported to create a queue without a name; some string
  # (even the empty string) must be passed in the +name+ parameter.
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
  # Again, note the durability property on a queue has no influence on
  # the persistence of published messages. A durable queue containing
  # transient messages will flush those messages on a restart.
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
  # Any remaining messages in the queue will be purged when the queue
  # is deleted regardless of the message's persistence setting.
  #
  # * :nowait => true | false (default true)
  # If set, the server will not respond to the method. The client should
  # not wait for a reply method.  If the server could not complete the
  # method it will raise a channel or connection exception.
  #
  def queue name, opts = {}
    queues[name] ||= Queue.new(self, name, opts)
  end

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
  def rpc name, obj = nil
    rpcs[name] ||= RPC.new(self, name, obj)
  end

  def close
    if @deferred_status == :succeeded
      send Protocol::Channel::Close.new(:reply_code => 200,
                                        :reply_text => 'bye',
                                        :method_id => 0,
                                        :class_id => 0)
    else
      @closing = true
    end
  end

  # Define a message and callback block to be executed on all
  # errors.
  def self.error msg = nil, &blk
    if blk
      @error_callback = blk
    else
      @error_callback.call(msg) if @error_callback and msg
    end
  end

  def prefetch(size)
    @prefetch_size = size
    send Protocol::Basic::Qos.new(:prefetch_size => 0, :prefetch_count => size, :global => false)
    self
  end

  # Asks the broker to redeliver all unacknowledged messages on this
  # channel.
  #
  # * requeue (default false)
  # If this parameter is false, the message will be redelivered to the original recipient.
  # If this flag is true, the server will attempt to requeue the message, potentially then
  # delivering it to an alternative subscriber.
  #
  def recover requeue = false
    send Protocol::Basic::Recover.new(:requeue => requeue)
    self
  end

  # Returns a hash of all the exchange proxy objects.
  #
  # Not typically called by client code.
  def exchanges
    @exchanges ||= {}
  end

  # Returns a hash of all the queue proxy objects.
  #
  # Not typically called by client code.
  def queues
    @queues ||= {}
  end

  def get_queue
    if block_given?
      (@get_queue_mutex ||= Mutex.new).synchronize{
        yield( @get_queue ||= [] )
      }
    end
  end

  # Returns a hash of all rpc proxy objects.
  #
  # Not typically called by client code.
  def rpcs
    @rcps ||= {}
  end

  # Queue objects keyed on their consumer tags.
  #
  # Not typically called by client code.
  def consumers
    @consumers ||= {}
  end

  def reset
    @deferred_status = nil
    @channel = nil
    initialize @connection

    @consumers = {}

    exs = @exchanges
    @exchanges = {}
    exs.each{ |_,e| e.reset } if exs

    qus = @queues
    @queues = {}
    qus.each{ |_,q| q.reset } if qus

    prefetch(@prefetch_size) if @prefetch_size
  end

  private

  def log *args
    return unless MQ.logging
    pp args
    puts
  end

  attr_reader :connection
  alias :conn :connection
end

#-- convenience wrapper (read: HACK) for thread-local MQ object

class MQ
  def MQ.default
    #-- XXX clear this when connection is closed
    Thread.current[:mq] ||= MQ.new
  end

  # Allows for calls to all MQ instance methods. This implicitly calls
  # MQ.new so that a new channel is allocated for subsequent operations.
  def MQ.method_missing meth, *args, &blk
    MQ.default.__send__(meth, *args, &blk)
  end
end

class MQ
  # unique identifier
  def MQ.id
    Thread.current[:mq_id] ||= "#{`hostname`.strip}-#{Process.pid}-#{Thread.current.object_id}"
  end
end