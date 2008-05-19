#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/vcard/iq/vcard'
include Jabber

class IqVcardTest < Test::Unit::TestCase
  def test_create
    v = Vcard::IqVcard.new
    assert_equal([], v.fields)
  end

  def test_create_with_fields
    v = Vcard::IqVcard.new({'FN' => 'B C', 'NICKNAME' => 'D'})
    assert_equal(['FN', 'NICKNAME'], v.fields.sort)
    assert_equal('B C', v['FN'])
    assert_equal('D', v['NICKNAME'])
    assert_equal(nil, v['x'])
  end

  def test_fields
    v = Vcard::IqVcard.new
    f = ['a', 'b', 'c', 'd', 'e']
    f.each { |s|
      v[s.downcase] = s.upcase
    }
    
    assert_equal(f, v.fields.sort)
    
    f.each { |s|
      assert_equal(s.upcase, v[s.downcase])
      assert_equal(nil, v[s.upcase])
    }
  end

  def test_deep
    v = Vcard::IqVcard.new({
      'FN' => 'John D. Random',
      'PHOTO/TYPE' => 'image/png',
      'PHOTO/BINVAL' => '===='})
    
      assert_equal(['FN', 'PHOTO/BINVAL', 'PHOTO/TYPE'], v.fields.sort)
      assert_equal('John D. Random', v['FN'])
      assert_equal('image/png', v['PHOTO/TYPE'])
      assert_equal('====', v['PHOTO/BINVAL'])
      assert_equal(nil, v['PHOTO'])
      assert_equal(nil, v['NICKNAME'])
  end
end
