$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'mq'

AMQP.start(:host => 'localhost') do

  def log *args
    p args
  end

  # AMQP.logging = true

  clock = MQ.new.fanout('clock')
  EM.add_periodic_timer(1){
    puts

    log :publishing, time = Time.now
    clock.publish(Marshal.dump(time))
  }

  amq = MQ.new
  amq.queue('every second').bind(amq.fanout('clock')).subscribe{ |time|
    log 'every second', :received, Marshal.load(time)
  }

  amq = MQ.new
  amq.queue('every 5 seconds').bind(amq.fanout('clock')).subscribe{ |time|
    time = Marshal.load(time)
    log 'every 5 seconds', :received, time if time.strftime('%S').to_i%5 == 0
  }

end

__END__

[:publishing, Thu Jul 17 20:14:00 -0700 2008]
["every 5 seconds", :received, Thu Jul 17 20:14:00 -0700 2008]
["every second", :received, Thu Jul 17 20:14:00 -0700 2008]

[:publishing, Thu Jul 17 20:14:01 -0700 2008]
["every second", :received, Thu Jul 17 20:14:01 -0700 2008]

[:publishing, Thu Jul 17 20:14:02 -0700 2008]
["every second", :received, Thu Jul 17 20:14:02 -0700 2008]

[:publishing, Thu Jul 17 20:14:03 -0700 2008]
["every second", :received, Thu Jul 17 20:14:03 -0700 2008]

[:publishing, Thu Jul 17 20:14:04 -0700 2008]
["every second", :received, Thu Jul 17 20:14:04 -0700 2008]

[:publishing, Thu Jul 17 20:14:05 -0700 2008]
["every 5 seconds", :received, Thu Jul 17 20:14:05 -0700 2008]
["every second", :received, Thu Jul 17 20:14:05 -0700 2008]

[:publishing, Thu Jul 17 20:14:06 -0700 2008]
["every second", :received, Thu Jul 17 20:14:06 -0700 2008]
