$:.unshift File.dirname(__FILE__) + '/../lib'
require 'mq'

MAX = 500

def log *args
  p args
end

# MQ.logging = true

EM.run{

  # worker

  log "prime checker", Process.pid, :started

  class Fixnum
    def prime?
      ('1' * self) !~ /^1?$|^(11+?)\1+$/
    end
  end

  MQ.queue('prime checker').subscribe{ |info, num|
    EM.defer(proc{

      log "prime checker #{Process.pid}-#{Thread.current.object_id}", :prime?, num
      if Integer(num).prime?
        MQ.queue(info.reply_to).publish(num, :reply_to => "#{Process.pid}-#{Thread.current.object_id}")
        EM.stop_event_loop if num == '499'
      end
      
    })
  }

  # controller

  MQ.queue('prime collector').subscribe{ |info, prime|
    log 'prime collector', :received, prime, :from, info.reply_to
    (@primes ||= []) << Integer(prime)
  }

  MAX.times do |i|
    EM.next_tick do
      MQ.queue('prime checker').publish((i+1).to_s, :reply_to => 'prime collector')
    end
  end

}