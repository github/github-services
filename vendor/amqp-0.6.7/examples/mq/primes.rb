$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'mq'

# check MAX numbers for prime-ness
MAX = 1000

# logging
def log *args
  p args
end

# spawn workers
workers = ARGV[0] ? (Integer(ARGV[0]) rescue 1) : 1
AMQP.fork(workers) do

  log MQ.id, :started

  class Fixnum
    def prime?
      ('1' * self) !~ /^1?$|^(11+?)\1+$/
    end
  end

  class PrimeChecker
    def is_prime? number
      log "prime checker #{MQ.id}", :prime?, number
      number.prime?
    end
  end

  MQ.rpc('prime checker', PrimeChecker.new)

end

# use workers to check which numbers are prime
AMQP.start(:host => 'localhost') do
  
  prime_checker = MQ.rpc('prime checker')

  (10_000...(10_000+MAX)).each do |num|
    log :checking, num

    prime_checker.is_prime?(num) { |is_prime|
      log :prime?, num, is_prime
      (@primes||=[]) << num if is_prime
      
      if (@responses = (@responses || 0) + 1) == MAX
        log :primes=, @primes
        EM.stop_event_loop
      end
    }

  end
  
end

__END__

$ uname -a
Linux gc 2.6.24-ARCH #1 SMP PREEMPT Sun Mar 30 10:50:22 CEST 2008 x86_64 Intel(R) Xeon(R) CPU X3220 @ 2.40GHz GenuineIntel GNU/Linux

$ cat /proc/cpuinfo | grep processor | wc -l
4

$ time ruby primes-simple.rb 

real  0m16.055s
user  0m16.052s
sys 0m0.000s

$ time ruby primes.rb 1 >/dev/null

real  0m18.278s
user  0m0.993s
sys 0m0.027s

$ time ruby primes.rb 2 >/dev/null

real  0m17.316s
user  0m0.967s
sys 0m0.053s

$ time ruby primes.rb 4 >/dev/null

real  0m8.229s
user  0m1.010s
sys 0m0.030s

$ time ruby primes.rb 8 >/dev/null

real  0m5.893s
user  0m1.023s
sys 0m0.050s

$ time ruby primes.rb 16 >/dev/null

real  0m5.601s
user  0m0.990s
sys 0m0.043s
