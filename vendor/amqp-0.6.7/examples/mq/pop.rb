$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'mq'
require 'pp'

Signal.trap('INT') { AMQP.stop{ EM.stop } }
Signal.trap('TERM'){ AMQP.stop{ EM.stop } }

AMQP.start do
  queue = MQ.queue('awesome')

  queue.publish('Totally rad 1')
  queue.publish('Totally rad 2')
  EM.add_timer(5){ queue.publish('Totally rad 3') }

  queue.pop{ |msg|
    unless msg
      # queue was empty
      p [Time.now, :queue_empty!]

      # try again in 1 second
      EM.add_timer(1){ queue.pop }
    else
      # process this message
      p [Time.now, msg]

      # get the next message in the queue
      queue.pop
    end
  }
end

__END__

[Wed Oct 15 15:24:30 -0700 2008, "Totally rad 1"]
[Wed Oct 15 15:24:30 -0700 2008, "Totally rad 2"]
[Wed Oct 15 15:24:30 -0700 2008, :queue_empty!]
[Wed Oct 15 15:24:31 -0700 2008, :queue_empty!]
[Wed Oct 15 15:24:32 -0700 2008, :queue_empty!]
[Wed Oct 15 15:24:33 -0700 2008, :queue_empty!]
[Wed Oct 15 15:24:34 -0700 2008, :queue_empty!]
[Wed Oct 15 15:24:35 -0700 2008, "Totally rad 3"]
[Wed Oct 15 15:24:35 -0700 2008, :queue_empty!]
[Wed Oct 15 15:24:36 -0700 2008, :queue_empty!]