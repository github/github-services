#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/roster/x/roster'
require 'xmpp4r/jid'
include Jabber

class Roster::XRosterTest < Test::Unit::TestCase
  def test_create
    r1 = Roster::XRoster.new
    assert_equal('x', r1.name)
    assert_equal('jabber:x:roster', r1.namespace)
    r2 = Roster::RosterX.new
    assert_equal('x', r2.name)
    assert_equal('http://jabber.org/protocol/rosterx', r2.namespace)
  end

  def test_import
    x1 = X.new
    x1.add_namespace('jabber:x:roster')
    x2 = X::import(x1)
    assert_equal(Roster::XRoster, x2.class)
    assert_equal('jabber:x:roster', x2.namespace)
  end

  def test_typed_add
    x = REXML::Element.new('x')
    x.add(REXML::Element.new('item'))
    r = Roster::XRoster.new.import(x)
    assert_kind_of(Roster::XRosterItem, r.first_element('item'))
    assert_kind_of(Roster::XRosterItem, r.typed_add(REXML::Element.new('item')))
  end
  
  def test_items
    j1 = Roster::XRosterItem.new
    assert_equal(JID.new(nil), j1.jid)
    assert_equal(nil, j1.iname)

    j2 = Roster::XRosterItem.new(JID.new('a@b/c'))
    assert_equal(JID.new('a@b/c'), j2.jid)
    assert_equal(nil, j2.iname)
    j3 = Roster::XRosterItem.new(JID.new('a@b/c'), 'Mr. Abc')
    assert_equal(JID.new('a@b/c'), j3.jid)
    assert_equal('Mr. Abc', j3.iname)
    assert_equal([], j3.groups)

    j3.groups = ['X', 'Y', 'Z']
    assert_equal(['X', 'Y', 'Z'], j3.groups)
  end

  def test_actions
    j = Roster::XRosterItem.new
    assert_equal(:add, j.action)

    j.action = :modify
    assert_equal(:modify, j.action)

    j.action = :delete
    assert_equal(:delete, j.action)

    j.action = :invalid
    assert_equal(:add, j.action)

    j.attributes['action'] = 'modify'
    assert_equal(:modify, j.action)

    j.attributes['action'] = 'invalid'
    assert_equal(:add, j.action)
  end
end
