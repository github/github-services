#!/usr/bin/env ruby

require 'bullshit'
require 'active_support'

class BC_Rails < Bullshit::TimeCase
  warmup    true
  duration  10

  def setup
    a = [ nil, false, true, "fÖßÄr", [ "n€st€d", true ], { "fooß" => "bär", "quux" => true } ]
    puts a.to_json
    @big = a * 100
  end

  def benchmark_generator
    @result = @big.to_json
  end

  def reset_benchmark_generator
    @result and @result.size > 2 + 6 * @big.size or raise @result.to_s
    if stack = Thread.current[:json_reference_stack]
      stack.clear
    end
  end
end
