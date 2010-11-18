$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'mq'
require 'pp'

EM.run do

  # connect to the amqp server
  connection = AMQP.connect(:host => 'localhost', :logging => false)
  
  # open a channel on the AMQP connection
  channel = MQ.new(connection)

  # declare a queue on the channel
  queue = MQ::Queue.new(channel, 'queue name')

  # create a fanout exchange
  exchange = MQ::Exchange.new(channel, :fanout, 'all queues')

  # bind the queue to the exchange
  queue.bind(exchange)

  # publish a message to the exchange
  exchange.publish('hello world')

  # subscribe to messages in the queue
  queue.subscribe do |headers, msg|
    pp [:got, headers, msg]
    connection.close{ EM.stop_event_loop }
  end
  
end

__END__

[:got,
 #<AMQP::Protocol::Header:0x1186270
  @klass=AMQP::Protocol::Basic,
  @properties=
   {:priority=>0,
    :exchange=>"all queues",
    :consumer_tag=>"queue name",
    :delivery_tag=>1,
    :delivery_mode=>1,
    :redelivered=>false,
    :content_type=>"application/octet-stream",
    :routing_key=>""},
  @size=11,
  @weight=0>,
 "hello world"]
