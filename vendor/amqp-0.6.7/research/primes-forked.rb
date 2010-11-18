$:.unshift File.dirname(__FILE__) + '/../lib'
require 'mq'

MAX = 5000

def EM.fork &blk
  raise if reactor_running?

  unless @forks
    at_exit{
      @forks.each{ |pid| Process.kill('KILL', pid) }
    }
  end

  (@forks ||= []) << Kernel.fork do
    EM.run(&blk)
  end
end

def log *args
  p args
end

# MQ.logging = true

# worker

  workers = ARGV[0] ? (Integer(ARGV[0]) rescue 2) : 2

  workers.times do
    EM.fork{
      log "prime checker", Process.pid, :started

      class Fixnum
        def prime?
          ('1' * self) !~ /^1?$|^(11+?)\1+$/
        end
      end

      MQ.queue('prime checker').subscribe{ |info, num|
        log "prime checker #{Process.pid}", :prime?, num
        if Integer(num).prime?
          MQ.queue(info.reply_to).publish(num, :reply_to => Process.pid)
        end
      }
    }
  end

# controller

  EM.run{
    MQ.queue('prime collector').subscribe{ |info, prime|
      log 'prime collector', :received, prime, :from, info.reply_to
      (@primes ||= []) << Integer(prime)
      EM.stop_event_loop if prime == '499'
    }

    MAX.times do |i|
      EM.next_tick do
        MQ.queue('prime checker').publish((i+1).to_s, :reply_to => 'prime collector')
      end
    end
  }
