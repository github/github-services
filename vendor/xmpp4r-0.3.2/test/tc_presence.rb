#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/presence'
include Jabber

class PresenceTest < Test::Unit::TestCase
  def test_create
    x = Presence::new()
    assert_equal("presence", x.name)
    assert_equal("jabber:client", x.namespace)
    assert_equal(nil, x.to)
    assert_equal(nil, x.show)
    assert_equal(nil, x.status)
    assert_equal(nil, x.priority)

    x = Presence::new(:away, "I am away", 23)
    assert_equal("presence", x.name)
    assert_equal(:away, x.show)
    assert_equal("away", x.show.to_s)
    assert_equal("I am away", x.status)
    assert_equal(23, x.priority)
  end

  def test_show
    x = Presence::new()
    assert_equal(nil, x.show)
    assert_raise(RuntimeError) { x.show = "a" }
    assert_equal(nil, x.show)
    assert_raise(RuntimeError) { x.show = 'away' }
    assert_equal(nil, x.show)
    x.show = :away
    assert_equal(:away, x.show)
    x.each_element('show') { |e| assert(e.class == REXML::Element, "<show/> is not REXML::Element") }
    x.show = nil
    assert_equal(nil, x.show)
    x.each_element('show') { |e| assert(true, "<show/> exists after 'show=nil'") }
    x.show = nil
    assert_equal(nil, x.show)

    showelement = REXML::Element.new('show')
    showelement.text = 'chat'
    x.add(showelement)
    assert_equal(:chat, x.show)
  end

  def test_status
    x = Presence::new()
    assert_equal(nil, x.status)
    x.status = "b"
    assert_equal("b", x.status)
    x.each_element('status') { |e| assert(e.class == REXML::Element, "<status/> is not REXML::Element") }
    x.status = nil
    assert_equal(nil, x.status)
    x.each_element('status') { |e| assert(true, "<status/> exists after 'status=nil'") }
    x.status = nil
    assert_equal(nil, x.status)
  end

  def test_priority
    x = Presence::new()
    assert_equal(nil, x.priority)
    x.priority = 5
    assert_equal(5, x.priority)
    x.each_element('priority') { |e| assert(e.class == REXML::Element, "<priority/> is not REXML::Element") }
    x.priority = "5"
    assert_equal(5, x.priority)
    x.priority = nil
    assert_equal(nil, x.priority)
    x.each_element('priority') { |e| assert(true, "<priority/> exists after 'priority=nil'") }
  end

  def test_type
    x = Presence::new()
    assert_equal(nil, x.type)
    x.type = :delete
    assert_equal(nil, x.type)
    x.type = nil
    assert_equal(nil, x.type)
    x.type = nil
    assert_equal(nil, x.type)
    [:error, :probe, :subscribe, :subscribed, :unavailable, :unsubscribe, :unsubscribed, nil].each { |type|
      x.type = type
      assert_equal(type, x.type)
    }
  end

  def test_chaining
    x = Presence::new()
    x.set_show(:xa).set_status("Plundering the fridge.").set_priority(0)
    assert_equal(:xa, x.show)
    assert_equal("Plundering the fridge.", x.status)
    assert_equal(0, x.priority)
  end

  def test_error
    x = Presence::new()
    e = REXML::Element::new('error')
    x.add(e)
    x2 = Presence::new.import(x)
    # test if, after an import, the error element is successfully changed
    # into an Error object.
    assert_equal(Error, x2.first_element('error').class)
  end

  def test_sample
    x = Presence::new
    require 'rexml/document'
    d = REXML::Document.new("<presence from='astro@spaceboyz.net/versionbot' to='astro@spaceboyz.net/edgarr' xmlns='jabber:client'>\n    <x from='astro@spaceboyz.net/versionbot' stamp='20050823T02:18:42' xmlns='jabber:x:delay'/><show>xa</show>\n    <status>I am the evil fingerprinting robot</status>\n  </presence>")
    x.import(d.root)
    num = 0
    x.each_element('show') { num += 1 }
    assert_equal(1, num)
    assert_equal(:xa, x.show)
    assert_equal('I am the evil fingerprinting robot', x.status)
  end

  def test_xpathbug
    require 'rexml/document'
    d = REXML::Document.new("<tag1 xmlns='ns1'><tag2 xmlns='ns2'/><tada>xa</tada></tag1>")
    x = d.root
    num = 0
    x.each_element('tada') {  num += 1 }
    assert_equal(1, num)
  end

  def test_compare_prio
    assert_equal(0, Presence::new(:chat, '', 5) <=> Presence::new(:chat, '', 5))
    assert_equal(-1, Presence::new(:chat, '', 4) <=> Presence::new(:chat, '', 5))
    assert_equal(1, Presence::new(:chat, '', 4) <=> Presence::new(:chat, '', 3))
    assert_equal(-1, Presence::new(:chat, '', nil) <=> Presence::new(:chat, '', 3))
    assert_equal(1, Presence::new(:chat, '', 10) <=> Presence::new(:chat, '', nil))
    assert_equal(0, Presence::new(:chat, '', nil) <=> Presence::new(:chat, '', nil))
  end

  def test_compare_interest
    unav = Presence::new.set_type(:unavailable)
    assert_equal(0, unav.cmp_interest(unav))
    assert_equal(1, unav.cmp_interest(Presence::new))
    assert_equal(-1, Presence::new.cmp_interest(unav))
    assert_equal(1, Presence::new(:chat).cmp_interest(Presence::new))
    assert_equal(-1, Presence::new(:away).cmp_interest(Presence::new(:dnd)))
  end

end
