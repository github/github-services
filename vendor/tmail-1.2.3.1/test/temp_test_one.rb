$:.unshift File.dirname(__FILE__)
require 'test_helper'
require 'tmail'
require 'kcode'
require 'time'

class TestMail < Test::Unit::TestCase
  include TMail::TextUtils

  def setup
    @mail = TMail::Mail.new
  end

  def lf( str )
    str.gsub(/\n|\r\n|\r/) { "\n" }
  end

  def crlf( str )
    str.gsub(/\n|\r\n|\r/) { "\r\n" }
  end

  def test_MIME
    # FIXME: test more.
    
    kcode('EUC') {
      mail = TMail::Mail.parse('From: hoge@example.jp (=?iso-2022-jp?B?GyRCJUYlOSVIGyhC?=)')
      assert_not_nil mail['From']
      
      expected = "\245\306\245\271\245\310"
      if expected.respond_to? :force_encoding
        expected.force_encoding(mail['From'].comments.first.encoding)
      end
      assert_equal [expected], mail['From'].comments

      expected = "From: hoge@example.jp (\245\306\245\271\245\310)\n\n"
      expected.force_encoding 'EUC-JP' if expected.respond_to? :force_encoding
      assert_equal expected, mail.to_s
      assert_equal expected, mail.decoded

      expected = "From: hoge@example.jp (=?iso-2022-jp?B?GyRCJUYlOSVIGyhC?=)\r\n\r\n"
      expected.force_encoding 'EUC-JP' if expected.respond_to? :force_encoding
      assert_equal expected, mail.encoded
    }
  end

end
