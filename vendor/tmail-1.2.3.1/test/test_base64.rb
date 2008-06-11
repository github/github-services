require 'test_helper'
require 'tmail/base64'
require 'test/unit'

class TestTMailBase64 < Test::Unit::TestCase
  def try(orig)
    ok = [orig].pack('m').delete("\r\n")
    result = TMail::Base64.encode(orig)
    assert_equal ok, result, "str=#{orig.inspect}"
    assert_equal orig, TMail::Base64.decode(result), "str=#{orig.inspect}"
  end

  def test_normal
    try ''
    try 'a'
    try 'ab'
    try 'abc'
    try 'abcd'
    try 'abcde'
    try 'abcdef'
    try 'abcdefg'
    try 'abcdefgh'
    try 'abcdefghi'
    try 'abcdefghij'
    try 'abcdefghijk'
    try 'abcdefghijkl'
    try 'abcdefghijklm'
    try 'abcdefghijklmn'
    try 'abcdefghijklmno'
    try 'abcdefghijklmnop'
    try 'abcdefghijklmnopq'
    try 'abcdefghijklmnopqr'
    try 'abcdefghijklmnopqrs'
    try 'abcdefghijklmnopqrst'
    try 'abcdefghijklmnopqrstu'
    try 'abcdefghijklmnopqrstuv'
    try 'abcdefghijklmnopqrstuvw'
    try 'abcdefghijklmnopqrstuvwx'
    try 'abcdefghijklmnopqrstuvwxy'
    try 'abcdefghijklmnopqrstuvwxyz'
  end

  def test_dangerous_chars
    ["\0", "\001", "\002", "\003", "\0xfd", "\0xfe", "\0xff"].each do |ch|
      1.upto(96) do |len|
        try ch * len
      end
    end
  end

  def test_random
    16.times do
      try make_random_string(96)
    end
  end

  def make_random_string(len)
    buf = ''
    len.times do
      buf << rand(255)
    end
    buf
  end
end
