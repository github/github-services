$:.unshift File.dirname(__FILE__) + '/../lib'
require 'mq'

MAX = 500

EM.run{

  def log *args
    p args
  end

  # MQ.logging = true

  if ARGV[0] == 'worker'

    log "prime checker #{Process.pid}", :started

    class Fixnum
      def prime?
        ('1' * self) !~ /^1?$|^(11+?)\1+$/
      end
    end

    MQ.queue('prime checker').subscribe{ |info, num|
      log "prime checker #{Process.pid}", :prime?, num
      if Integer(num).prime?
        MQ.queue(info.reply_to).publish(num, :reply_to => Process.pid)
        EM.stop_event_loop if num == (MAX-1).to_s
      end
    }

  elsif ARGV[0] == 'controller'

    MQ.queue('prime collector').subscribe{ |info, prime|
      log 'prime collector', :received, prime, :from, info.reply_to
      (@primes ||= []) << Integer(prime)
    }

    MAX.times do |i|
      EM.next_tick do
        MQ.queue('prime checker').publish((i+1).to_s, :reply_to => 'prime collector')
      end
    end

  else # run n workers and 1 controller as an example

    workers = ARGV[0] ? (Integer(ARGV[0]) rescue 2) : 2

    ([ :worker ] * workers + [ :controller ]).each do |type|
      log :spawning, "`ruby #{$0} #{type}`"

      EM.popen("ruby #{$0} #{type}") do |c|
        def c.receive_data data
          puts data
        end

        def c.unbind
          EM.stop_event_loop
        end
      end
    end

  end
}

__END__

["prime checker", :started, {:pid=>1958}]
["prime checker", :started, {:pid=>1957}]
["prime checker", :started, {:pid=>1956}]
["prime checker", :prime?, "1", {:pid=>1958}]
["prime checker", :prime?, "2", {:pid=>1957}]
["prime collector", :received, "2", {:from_pid=>"1957"}]
["prime checker", :prime?, "3", {:pid=>1956}]
["prime collector", :received, "3", {:from_pid=>"1956"}]
["prime checker", :prime?, "4", {:pid=>1958}]
["prime checker", :prime?, "5", {:pid=>1957}]
["prime collector", :received, "5", {:from_pid=>"1957"}]
["prime checker", :prime?, "6", {:pid=>1956}]
["prime checker", :prime?, "7", {:pid=>1958}]
["prime collector", :received, "7", {:from_pid=>"1958"}]
["prime checker", :prime?, "8", {:pid=>1957}]
["prime checker", :prime?, "9", {:pid=>1956}]
["prime checker", :prime?, "10", {:pid=>1958}]
["prime checker", :prime?, "11", {:pid=>1957}]
["prime collector", :received, "11", {:from_pid=>"1957"}]
["prime checker", :prime?, "12", {:pid=>1956}]
["prime checker", :prime?, "13", {:pid=>1958}]
["prime collector", :received, "13", {:from_pid=>"1958"}]
["prime checker", :prime?, "14", {:pid=>1957}]
["prime checker", :prime?, "15", {:pid=>1956}]
["prime checker", :prime?, "16", {:pid=>1958}]
["prime checker", :prime?, "17", {:pid=>1957}]
["prime collector", :received, "17", {:from_pid=>"1957"}]
["prime checker", :prime?, "18", {:pid=>1956}]
["prime checker", :prime?, "19", {:pid=>1958}]
["prime collector", :received, "19", {:from_pid=>"1958"}]
["prime checker", :prime?, "20", {:pid=>1957}]
["prime checker", :prime?, "21", {:pid=>1956}]
["prime checker", :prime?, "22", {:pid=>1958}]
["prime checker", :prime?, "23", {:pid=>1957}]
["prime collector", :received, "23", {:from_pid=>"1957"}]
["prime checker", :prime?, "24", {:pid=>1956}]
["prime checker", :prime?, "25", {:pid=>1958}]
["prime checker", :prime?, "26", {:pid=>1957}]
["prime checker", :prime?, "27", {:pid=>1956}]
["prime checker", :prime?, "28", {:pid=>1958}]
["prime checker", :prime?, "29", {:pid=>1957}]
["prime collector", :received, "29", {:from_pid=>"1957"}]
["prime checker", :prime?, "30", {:pid=>1956}]
["prime checker", :prime?, "31", {:pid=>1958}]
["prime collector", :received, "31", {:from_pid=>"1958"}]
["prime checker", :prime?, "32", {:pid=>1957}]
["prime checker", :prime?, "33", {:pid=>1956}]
["prime checker", :prime?, "34", {:pid=>1958}]
["prime checker", :prime?, "35", {:pid=>1957}]
["prime checker", :prime?, "36", {:pid=>1956}]
["prime checker", :prime?, "37", {:pid=>1958}]
["prime collector", :received, "37", {:from_pid=>"1958"}]
["prime checker", :prime?, "38", {:pid=>1957}]
["prime checker", :prime?, "39", {:pid=>1956}]
["prime checker", :prime?, "40", {:pid=>1958}]
["prime checker", :prime?, "41", {:pid=>1957}]
["prime collector", :received, "41", {:from_pid=>"1957"}]
["prime checker", :prime?, "42", {:pid=>1956}]
["prime checker", :prime?, "43", {:pid=>1958}]
["prime collector", :received, "43", {:from_pid=>"1958"}]
["prime checker", :prime?, "44", {:pid=>1957}]
["prime checker", :prime?, "45", {:pid=>1956}]
["prime checker", :prime?, "46", {:pid=>1958}]
["prime checker", :prime?, "47", {:pid=>1957}]
["prime collector", :received, "47", {:from_pid=>"1957"}]
["prime checker", :prime?, "48", {:pid=>1956}]
["prime checker", :prime?, "49", {:pid=>1958}]
["prime checker", :prime?, "50", {:pid=>1957}]