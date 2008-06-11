# base64 benchmark
#
# pass 'c' as first argument to bench c lib.

require 'benchmark'

module TMail
  module Base64
  end
end

$lib   = ARGV[0]
$count = 10000
$size  = 5000

def make_random_string(len)
  buf = ''
  len.times do
    buf << rand(255)
  end
  buf
end

def encode_and_decode(orig)
  #ok = [orig].pack('m').delete("\r\n")
end

if $lib == "c"
  $lib = "   c"
  require 'ext/base64_c/tmail/base64_c.bundle'
else
  $lib = "ruby"
  require 'lib/tmail/base64_r.rb'
end

def benchmark!
  Benchmark.bm do |x|
    x.report("#{$lib} #{$count.to_s}/#{$size}: ") do
      $count.times do
        orig = make_random_string($size)
        result = TMail::Base64.encode(orig)
        TMail::Base64.decode(result)
      end
    end
  end
end

benchmark!
