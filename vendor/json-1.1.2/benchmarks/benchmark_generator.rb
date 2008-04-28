#!/usr/bin/env ruby

require 'bullshit'
$KCODE='utf8'
if ARGV.shift == 'pure'
  require 'json/pure'
else
  require 'json/ext'
end

class BC_Generator < Bullshit::TimeCase
  include JSON

  warmup    true
  duration  10

  def setup
    a = [ nil, false, true, "fÖßÄr", [ "n€st€d", true ], { "fooß" => "bär", "quux" => true } ]
    puts JSON[a]
    @big = a * 100
  end

  def benchmark_generator_fast
    @result = JSON.fast_generate(@big)
  end

  def reset_benchmark_generator_fast
    @result and @result.size > 2 + 6 * @big.size or raise @result.to_s
  end

  def benchmark_generator_safe
    @result = JSON.generate(@big)
  end

  def reset_benchmark_generator_safe
    @result and @result.size > 2 + 6 * @big.size or raise @result.to_s
  end

  def benchmark_generator_pretty
    @result = JSON.pretty_generate(@big)
  end

  def reset_benchmark_generator_pretty
    @result and @result.size > 2 + 6 * @big.size or raise @result.to_s
  end

  compare :generator_fast, :generator_safe, :generator_pretty
end
