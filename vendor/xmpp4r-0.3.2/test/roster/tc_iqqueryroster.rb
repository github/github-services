#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/roster/iq/roster'
require 'xmpp4r/jid'
require 'xmpp4r/iq'
include Jabber

class Roster::IqQueryRosterTest < Test::Unit::TestCase
  def test_create
    r = Roster::IqQueryRoster::new
    assert_equal('jabber:iq:roster', r.namespace)
    assert_equal(r.to_a.size, 0)
    assert_equal(r.to_a, [])
    assert_equal(r.to_s, "<query xmlns='jabber:iq:roster'/>")
  end

  def test_import
    iq = Iq::new
    q = REXML::Element::new('query')
    q.add_namespace('jabber:iq:roster')
    iq.add(q)
    iq2 = Iq::new.import(iq)
    assert_equal(Roster::IqQueryRoster, iq2.query.class)
  end

  def test_answer
    iq = Iq::new_rosterget
    assert_equal(:get, iq.type)
    assert_nil(iq.to)
    assert_equal('jabber:client', iq.namespace)
    assert_equal('jabber:iq:roster', iq.queryns)
    assert_equal(0, iq.query.children.size)

    iq2 = iq.answer(true)
    assert_equal(:get, iq2.type)
    assert_nil(iq2.from)
    assert_equal('jabber:client', iq2.namespace)
    assert_equal('jabber:iq:roster', iq2.queryns)
    assert_equal(0, iq2.query.children.size)
  end

  def test_xmlns
    ri = Roster::RosterItem.new
    assert_equal('jabber:iq:roster', ri.namespace)
    assert_equal('jabber:iq:roster', ri.attributes['xmlns'])

    r = Roster::IqQueryRoster.new
    assert_equal('jabber:iq:roster', r.namespace)
    assert_equal('jabber:iq:roster', r.attributes['xmlns'])

    r.add(ri)

    assert_equal('jabber:iq:roster', ri.namespace)
    assert_nil(ri.attributes['xmlns'])
  end

  def test_items
    r = Roster::IqQueryRoster::new
    r.add(Roster::RosterItem.new)
    r.add(Roster::RosterItem.new(JID.new('a@b/d'), 'ABC', :none, :subscribe)).groups = ['a']
    itemstr = "<item jid='astro@spaceboyz.net' name='Astro' subscribtion='both'>" \
            + "<group>SpaceBoyZ</group><group>xmpp4r</group></item>"
    r.typed_add(REXML::Document.new(itemstr).root)

    r.each { |item|
      assert_equal(item, r[item.jid])
    }

    r.to_a.each { |item|
      assert_equal(item, r[item.jid])
    }

    assert_equal(JID.new, r.to_a[0].jid)
    assert_equal(nil, r.to_a[0].iname)
    assert_equal(nil, r.to_a[0].subscription)
    assert_equal(nil, r.to_a[0].ask)

    assert_equal(JID.new('a@b/d'), r.to_a[1].jid)
    assert_equal('ABC', r.to_a[1].iname)
    assert_equal(:none, r.to_a[1].subscription)
    assert_equal(:subscribe, r.to_a[1].ask)

    assert_equal(REXML::Document.new(itemstr).root.to_s, r.to_a[2].to_s)
  end

  def test_dupitems
    r = Roster::IqQueryRoster::new
    jid = JID::new('a@b')
    jid2 = JID::new('c@d')
    ri = Roster::RosterItem::new(jid, 'ab')
    r.add(ri)
    assert_equal('ab', ri.iname)
    assert_equal('ab', r[jid].iname)
    ri.iname = 'cd'
    assert_equal('cd', ri.iname)
    # There are no shallow copies - everything is alright.
    assert_equal('cd', r[jid].iname)

    r.add(ri)
    assert_equal('cd', r[jid].iname)
    assert_equal(ri, r[jid])

    ri.jid = jid2
    assert_equal(nil, r[jid])
    assert_equal(ri, r[jid2])
    assert_equal(2, r.to_a.size)

    r.each_element('item') { |item|
      assert_equal(ri, item)
      assert_equal(ri.jid, item.jid)
      assert_equal(ri.iname, item.iname)
      assert_equal(jid2, item.jid)
      assert_equal('cd', item.iname)
    }
  end
end

class Roster::RosterItemTest < Test::Unit::TestCase
  def test_create
    ri = Roster::RosterItem::new
    assert_equal(JID.new, ri.jid)
    assert_equal(nil, ri.iname)
    assert_equal(nil, ri.subscription)
    assert_equal(nil, ri.ask)

    ri = Roster::RosterItem::new(JID.new('a@b/c'), 'xyz', :both, nil)
    assert_equal(JID.new('a@b/c'), ri.jid)
    assert_equal('xyz', ri.iname)
    assert_equal(:both, ri.subscription)
    assert_equal(nil, ri.ask)
  end

  def test_modify
    ri = Roster::RosterItem::new(JID.new('a@b/c'), 'xyz', :both, :subscribe)

    assert_equal(JID.new('a@b/c'), ri.jid)
    ri.jid = nil
    assert_equal(JID::new, ri.jid)

    assert_equal('xyz', ri.iname)
    ri.iname = nil
    assert_equal(nil, ri.iname)

    assert_equal(:both, ri.subscription)
    ri.subscription = nil
    assert_equal(nil, ri.subscription)

    assert_equal(:subscribe, ri.ask)
    ri.ask = nil
    assert_equal(nil, ri.ask)
  end

  def test_groupdeletion
    ri = Roster::RosterItem::new
    g1 = ['a', 'b', 'c']
    ri.groups = g1
    assert_equal(g1, ri.groups.sort)
    g2 = ['c', 'd', 'e']
    ri.groups = g2
    assert_equal(g2, ri.groups.sort)
  end

  def test_dupgroups
    ri = Roster::RosterItem::new
    mygroups = ['a', 'a', 'b']
    ri.groups = mygroups
    assert_equal(mygroups.uniq, ri.groups)
  end
end
