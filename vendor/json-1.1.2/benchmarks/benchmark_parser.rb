#!/usr/bin/env ruby

require 'bullshit'
if ARGV.shift == 'pure'
  require 'json/pure'
else
  require 'json/ext'
end

class BC_Parser < Bullshit::TimeCase
  include JSON

  warmup    true
  duration  10

  def setup
    a = [ nil, false, true, "fÖß\nÄr", [ "n€st€d", true ], { "fooß" => "bär", "qu\r\nux" => true } ]
    @big = a * 100
    @json = JSON.generate(@big)
  end

  def benchmark_parser
    a = JSON.parse(@json)
    a == @big or raise "not equal"
  end
end
