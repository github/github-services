$:.unshift File.dirname(__FILE__) + '/../lib'
require 'rubygems'
require 'amqp'

# AMQP.start do |amqp|
#   amqp.channel!(1)
# 
#   q = amqp.queue.declare(:queue => 'test',
#                          :exclusive => false,
#                          :auto_delete => true)
# 
#   q.bind(:exchange => '',
#          :routing_key => 'test_route')
# 
#   amqp.basic.consume(:queue => q,
#                      :no_local => false,
#                      :no_ack => true) { |header, body|
#     p ['got', header, body]
#   }
# end

AMQP.start do |amqp|
  amqp.exchange('my_exchange', :topic) do |e|
    e.publish(routing_key, data, :header => 'blah')
  end
  
  amqp.queue('my_queue').subscribe do |header, body|
    p ['got', header, body]
  end
end

def MQ.method_missing meth, *args, &blk
  (Thread.current[:mq] ||= MQ.new).__send__(meth, *args, &blk)
end

mq = MQ.new
mq.direct.publish('alkjsdf', :key => 'name')
mq.topic # 'amq.topic'
mq.topic('test').publish('some data', :key => 'stock.usd.*')

# amq.queue('user1').bind(amq.topic('conversation.1'))

mq.queue('abc').get{}
mq.queue('abc').peek{}
mq.queue('abc').subscribe{ |body|
  
}

mq.queue('abc').bind(:exchange => mq.topic, :routing_key => 'abc', :nowait => true, :arguments => {})

if $0 =~ /bacon/ or __FILE__ == $0
  require 'bacon'

  describe MQ do
    before do
      @mq = MQ.new
    end

    should 'have a channel' do
      @mq.channel.should.be.kind_of? Fixnum
      @mq.channel.should == 1
    end

    should 'give each thread a message queue' do
      class MQ
        @@cur_channel = 0
      end
      MQ.channel.should == 1
      Thread.new{ MQ.channel }.value.should == 2
      Thread.new{ MQ.channel }.value.should == 3
    end

    should 'create direct exchanges' do
      @mq.direct.name.should == 'amq.direct'
      @mq.direct(nil).name.should =~ /^\d+$/
      @mq.direct('name').name.should == 'name'
    end

    should 'create fanout and topic exchanges' do
      @mq.fanout.name.should == 'amq.fanout'
      @mq.topic.name.should == 'amq.topic'
    end

    should 'create queues' do
      q = @mq.queue('test')
    end
  end
end