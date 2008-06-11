# encoding: utf-8 
require 'test_helper'
require 'tmail/port'
require 'tmail/encode'
require 'nkf'
require 'test/unit'

class TestEncode < Test::Unit::TestCase

  SRCS = [
"a cde あいうえおあいうえおあいうえおあいうえおあいうえお", #1
"a cde あいうえおあいうえおあいうえおあいうえおあいうえ", #2
"a cde あいうえおあいうえおあいうえおあいうえおあいう", #3
"a cde あいうえおあいうえおあいうえおあいうえおあい", #4
"a cde あいうえおあいうえおあいうえおあいうえおあ", #5
"a cde あいうえおあいうえおあいうえおあいうえお", #6 #
"a cde あいうえおあいうえおあいうえおあいうえ", #7
"a cde あいうえおあいうえおあいうえおあいう", #8
"a cde あいうえおあいうえおあいうえおあい", #9
"a cde あいうえおあいうえおあいうえおあ", #10
"a cde あいうえおあいうえおあいうえお", #11
"a cde あいうえおあいうえおあいうえ", #12
"a cde あいうえおあいうえおあいう", #13
"a cde あいうえおあいうえおあい", #14
"a cde あいうえおあいうえおあ", #15
"a cde あいうえおあいうえお", #16
"a cde あいうえおあいうえ", #17
"a cde あいうえおあいう", #18
"a cde あいうえおあい", #19
"a cde あいうえおあ", #20
"a cde あいうえお", #21
"a cde あいうえ", #22
"a cde あいう", #23
"a cde あい", #24
"a cde あ", #25
"aあa aあa aあa aあa aあa aあa" #26
  ]

  OK = [
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIiQkJCYkKCQqGyhC?=", #1
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIiQkJCYkKBsoQg==?=", #2
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIiQkJCYbKEI=?=", #3
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIiQkGyhC?=", #4
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIhsoQg==?=", #5
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCobKEI=?=", #6
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoGyhC?=", #7
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJhsoQg==?=", #8
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQbKEI=?=", #9
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=", #10
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqGyhC?=", #11
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKBsoQg==?=", #12
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=', #13
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkGyhC?=', #14
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIhsoQg==?=', #15
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCobKEI=?=', #16
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoGyhC?=', #17
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJhsoQg==?=', #18
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQbKEI=?=', #19
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiGyhC?=', #20
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKhsoQg==?=', #21
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgbKEI=?=', #22
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmGyhC?=', #23
 'a cde =?iso-2022-jp?B?GyRCJCIkJBsoQg==?=', #24
 'a cde =?iso-2022-jp?B?GyRCJCIbKEI=?=', #25
 "=?iso-2022-jp?B?YRskQiQiGyhCYSBhGyRCJCIbKEJhIGEbJEIkIhsoQmEgYRskQiQiGyhCYSBh?=\r\n\t=?iso-2022-jp?B?GyRCJCIbKEJhIGEbJEIkIhsoQmE=?=" #26
  ]

  def test_s_encode
    SRCS.each_index do |i|
      assert_equal crlf(OK[i]), 
                   TMail::Encoder.encode(NKF.nkf('-j', SRCS[i]))
    end
  end

  def crlf( str )
    str.gsub(/\n|\r\n|\r/) { "\r\n" }
  end
  
  def test_wrapping_an_email_with_whitespace_at_position_zero
    # This email is a spam mail designed to break mailers...  evil.
    mail = TMail::Mail.load("#{File.dirname(__FILE__)}/fixtures/raw_attack_email_with_zero_length_whitespace")
    assert_nothing_raised(Exception) { mail.encoded }
  end

end
