#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/message'
include Jabber

class MessageTest < Test::Unit::TestCase
  def test_create
    x = Message::new()
    assert_equal("message", x.name)
    assert_equal("jabber:client", x.namespace)
    assert_equal(nil, x.to)
    assert_equal(nil, x.body)

    x = Message::new("lucas@linux.ensimag.fr", "coucou")
    assert_equal("message", x.name)
    assert_equal("lucas@linux.ensimag.fr", x.to.to_s)
    assert_equal("coucou", x.body)
  end

  def test_import
    x = Message::new
    assert_kind_of(REXML::Element, x.typed_add(REXML::Element.new('thread')))
    assert_kind_of(X, x.typed_add(REXML::Element.new('x')))
    assert_kind_of(X, x.x)
  end

  def test_type
    x = Message.new
    assert_equal(nil, x.type)
    x.type = :chat
    assert_equal(:chat, x.type)
    assert_equal(x, x.set_type(:error))
    assert_equal(:error, x.type)
    x.type = :groupchat
    assert_equal(:groupchat, x.type)
    x.type = :headline
    assert_equal(:headline, x.type)
    x.type = :normal
    assert_equal(:normal, x.type)
    x.type = :invalid
    assert_equal(nil, x.type)
  end

  def test_body
    x = Message::new()
    assert_equal(nil, x.body)
    assert_equal(x, x.set_body("trezrze ezfrezr ezr zer ezr ezrezrez ezr z"))
    assert_equal("trezrze ezfrezr ezr zer ezr ezrezrez ezr z", x.body)
    x.body = "2"
    assert_equal("2", x.body)
  end

  def test_subject
    x = Message::new
    assert_equal(nil, x.subject)
    subject = REXML::Element.new('subject')
    subject.text = 'A'
    x.add(subject)
    assert_equal('A', x.subject)
    x.subject = 'Test message'
    assert_equal('Test message', x.subject)
    x.each_element('subject') { |s| assert_equal('Test message', s.text) }
    assert_equal(x, x.set_subject('Breaking news'))
    assert_equal('Breaking news', x.subject)
  end

  def test_thread
    x = Message::new
    assert_equal(nil, x.thread)
    thread = REXML::Element.new('thread')
    thread.text = '123'
    x.add(thread)
    assert_equal('123', x.thread)
    x.thread = '321'
    assert_equal('321', x.thread)
    x.each_element('thread') { |s| assert_equal('321', s.text) }
    assert_equal(x, x.set_thread('abc'))
    assert_equal('abc', x.thread)
  end

  def test_error
    x = Message::new()
    assert_equal(nil, x.error)
    e = REXML::Element::new('error')
    x.add(e)
    # test if, after an import, the error element is successfully changed
    # into an Error object.
    x2 = Message::new.import(x)
    assert_equal(Error, x2.first_element('error').class)
  end

  def test_answer
    orig = Message::new
    orig.from = 'a@b'
    orig.to = 'b@a'
    orig.id = '123'
    orig.type = :chat
    orig.add(REXML::Element.new('x'))

    answer = orig.answer
    assert_equal(JID.new('b@a'), answer.from)
    assert_equal(JID.new('a@b'), answer.to)
    assert_equal('123', answer.id)
    assert_equal(:chat, answer.type)
    answer.each_element { |e|
      assert_equal('x', e.name)
      assert_kind_of(X, e)
    }
  end
end
