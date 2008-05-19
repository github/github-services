#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/error'
require 'xmpp4r/message'
include Jabber

class ErrorTest < Test::Unit::TestCase
  def test_create
    e = Error::new
    assert_equal(nil, e.error)
    assert_equal(nil, e.code)
    assert_equal(nil, e.type)
    assert_equal(nil, e.text)
  end

  def test_create2
    e = Error::new('payment-required')
    assert_equal('payment-required', e.error)
    assert_equal(402, e.code)
    assert_equal(:auth, e.type)
    assert_equal(nil, e.text)
  end

  def test_create3
    e = Error::new('gone', 'User moved to afterlife.gov')
    assert_equal('gone', e.error)
    assert_equal(302, e.code)
    assert_equal(:modify, e.type)
    assert_equal('User moved to afterlife.gov', e.text)
  end

  def test_create_invalid
    assert_raise(RuntimeError) {
      e = Error::new('invalid error')
    }
  end

  def test_type
    e = Error::new
    assert_nil(e.type)
    e.type = :auth
    assert_equal(:auth, e.type)
    e.type = :cancel
    assert_equal(:cancel, e.type)
    e.type = :continue
    assert_equal(:continue, e.type)
    e.type = :modify
    assert_equal(:modify, e.type)
    e.type = :wait
    assert_equal(:wait, e.type)
    e.type = nil
    assert_nil(e.type)
  end

  def test_code
    e = Error::new
    assert_nil(e.code)
    e.code = 404
    assert_equal(404, e.code)
    assert_equal("<error code='404'/>", e.to_s)
    e.code = nil
    assert_nil(e.code)
  end

  def test_error
    e = Error::new
    assert_nil(e.error)
    e.error = 'gone'
    assert_equal('gone', e.error)
    assert_raise(RuntimeError) {
      e.error = nil
    }
  end

  def test_stanzas
    m = Message.new
    assert_equal(nil, m.error)
    m.typed_add(Error.new)
    assert_equal('<error/>', m.error.to_s)
  end

  def test_sample_normal
    src = '<error code="302" type="modify"><gone xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/><text xmlns="urn:ietf:params:xml:ns:xmpp-stanzas">...</text></error>'
    e = Error.new.import(REXML::Document.new(src).root)
    assert_equal(:modify, e.type)
    assert_equal(302, e.code)
    assert_equal('gone', e.error)
    assert_equal('...', e.text)
  end

  def test_sample_muc
    src = '<error code="409">Please choose a different nickname.</error>'
    e = Error.new.import(REXML::Document.new(src).root)
    assert_equal(nil, e.type)
    assert_equal(409, e.code)
    assert_equal(nil, e.error)
    assert_equal('Please choose a different nickname.', e.text)
  end
end
