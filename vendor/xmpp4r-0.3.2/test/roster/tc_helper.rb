#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/roster/helper/roster'
require 'xmpp4r/semaphore'
include Jabber

class Roster::HelperTest < Test::Unit::TestCase
  include ClientTester

  def test_simple
    state { |iq|
      assert_kind_of(Iq, iq)
      assert_equal(:get, iq.type)
      assert_nil(iq.to)
      assert_equal('jabber:iq:roster', iq.queryns)

      send("<iq type='result'><query xmlns='jabber:iq:version'/></iq>")
      send("<iq type='result' id='#{iq.id}'>
              <query xmlns='jabber:iq:roster'>
                <item jid='a@b.c' subscription='both'/>
                <item jid='b@b.c' name='b guy' subscription='from' ask='subscribe'/>
                <item jid='123@xyz' name='123' subscription='to'/>
              </query>
            </iq>")
    }

    query_waiter = Semaphore.new
    h = Roster::Helper::new(@client)
    h.add_query_callback { |iq|
      query_waiter.run
    }
    wait_state
    query_waiter.wait

    assert_equal([nil], h.groups)
    jids = h.find_by_group(nil).collect { |item| item.jid }.sort
    assert_equal([JID.new('123@xyz'), JID.new('a@b.c'), JID.new('b@b.c')], jids)
    assert_equal(1, h.find('123@xyz/res').size)

    assert_kind_of(Roster::Helper::RosterItem, h['a@b.c'])
    assert_equal(JID.new('a@b.c'), h['a@b.c'].jid)
    assert_nil(h['a@b.c'].iname)
    assert_equal(:both, h['a@b.c'].subscription)
    assert_nil(h['a@b.c'].ask)

    assert_kind_of(Roster::Helper::RosterItem, h[JID.new('b@b.c')])
    assert_equal(JID.new('b@b.c'), h['b@b.c'].jid)
    assert_equal('b guy', h['b@b.c'].iname)
    assert_equal(:from, h['b@b.c'].subscription)
    assert_equal(:subscribe, h['b@b.c'].ask)

    assert_kind_of(Roster::Helper::RosterItem, h['123@xyz'])
    assert_equal(JID.new('123@xyz'), h['123@xyz'].jid)
    assert_equal('123', h['123@xyz'].iname)
    assert_equal(:to, h['123@xyz'].subscription)
    assert_nil(h['123@xyz'].ask)

    assert_nil(h['c@b.c'])
    assert_nil(h[JID.new('c@b.c')])
  end

  def test_rosterpush
    state { |iq|
      send("<iq type='result' id='#{iq.id}'>
              <query xmlns='jabber:iq:roster'>
              </query>
            </iq>")
    }

    query_waiter = Semaphore.new
    h = Roster::Helper::new(@client)
    h.add_query_callback { |iq| query_waiter.run }
    wait_state
    query_waiter.wait

    assert_equal([], h.groups)
    assert_nil(h['a@b.c'])

    send("<iq type='set'>
            <query xmlns='jabber:iq:roster'>
              <item jid='a@b.c'/>
            </query>
          </iq>")
    query_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, h['a@b.c'])
    assert_equal(JID.new('a@b.c'), h['a@b.c'].jid)
    assert_nil(h['a@b.c'].iname)
    assert_nil(h['a@b.c'].subscription)
    assert_nil(h['a@b.c'].ask)

    send("<iq type='set'>
            <query xmlns='jabber:iq:roster'>
              <item jid='a@b.c' subscription='from' name='ABC' ask='subscribe'/>
            </query>
          </iq>")
    query_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, h['a@b.c'])
    assert_equal(JID.new('a@b.c'), h['a@b.c'].jid)
    assert_equal('ABC', h['a@b.c'].iname)
    assert_equal(:from, h['a@b.c'].subscription)
    assert_equal(:subscribe, h['a@b.c'].ask)

    send("<iq type='set'>
            <query xmlns='jabber:iq:roster'>
              <item jid='a@b.c'/>
            </query>
          </iq>")
    query_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, h['a@b.c'])
    assert_equal(JID.new('a@b.c'), h['a@b.c'].jid)
    assert_nil(h['a@b.c'].iname)
    assert_nil(h['a@b.c'].subscription)
    assert_nil(h['a@b.c'].ask)

    send("<iq type='set'>
            <query xmlns='jabber:iq:roster'>
              <item jid='a@b.c' subscription='remove'/>
            </query>
          </iq>")
    query_waiter.wait

    assert_nil(h['a@b.c'])
  end

  def test_presence
    state { |iq|
      send("<iq type='result' id='#{iq.id}'>
              <query xmlns='jabber:iq:roster'>
                <item jid='a@b.c' subscription='both'/>
              </query>
            </iq>")
    }

    query_waiter = Semaphore.new
    presence_waiter = Semaphore.new
    h = Roster::Helper::new(@client)
    h.add_query_callback { |iq|
      query_waiter.run
    }
    cb_item, cb_op, cb_p = nil, nil, nil
    h.add_presence_callback { |item,oldpres,pres|
      # HACK:
      # if two stanzas are expected for one sent stanza,
      # race conditions may appear here
      Thread.pass

      cb_item, cb_op, cb_p = item, oldpres, pres
      presence_waiter.run
    }

    wait_state
    query_waiter.wait

    assert_equal(false, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(0, presences)

    send("<presence from='a@b.c/r'/>")
    presence_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, cb_item)
    assert_nil(cb_op)
    assert_kind_of(Presence, cb_p)
    assert_nil(cb_p.type)
    assert_equal(true, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(1, presences)

    send("<presence from='a@b.c/r2'/>")
    presence_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, cb_item)
    assert_nil(cb_op)
    assert_kind_of(Presence, cb_p)
    assert_nil(cb_p.type)
    assert_equal(true, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(2, presences)

    send("<presence from='a@b.c/r'/>")
    presence_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, cb_item)
    assert_kind_of(Presence, cb_op)
    assert_nil(cb_op.type)
    assert_kind_of(Presence, cb_p)
    assert_nil(cb_p.type)
    assert_equal(true, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(2, presences)

    send("<presence from='a@b.c/r' type='error'/>")
    presence_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, cb_item)
    assert_kind_of(Presence, cb_op)
    assert_nil(cb_op.type)
    assert_kind_of(Presence, cb_p)
    assert_equal(:error, cb_p.type)
    assert_equal(true, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(2, presences)

    send("<presence from='a@b.c/r2' type='unavailable'/>")
    presence_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, cb_item)
    assert_kind_of(Presence, cb_op)
    assert_nil(cb_op.type)
    assert_kind_of(Presence, cb_p)
    assert_equal(:unavailable, cb_p.type)
    assert_equal(false, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(2, presences)

    send("<presence from='a@b.c/r'/>")
    presence_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, cb_item)
    assert_kind_of(Presence, cb_op)
    assert_equal(:error, cb_op.type)
    assert_kind_of(Presence, cb_p)
    assert_nil(cb_p.type)
    assert_equal(true, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(2, presences)

    send("<presence from='a@b.c/r2'/>")
    presence_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, cb_item)
    assert_kind_of(Presence, cb_op)
    assert_equal(:unavailable, cb_op.type)
    assert_kind_of(Presence, cb_p)
    assert_nil(cb_p.type)
    assert_equal(true, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(2, presences)

    send("<presence from='a@b.c' type='error'/>")
    2.times {
      presence_waiter.wait

      assert_kind_of(Roster::Helper::RosterItem, cb_item)
      assert_kind_of(Presence, cb_op)
      assert_kind_of(Presence, cb_p)
      assert_equal(:error, cb_p.type)
    }
    assert_equal(false, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(1, presences)

    send("<presence from='a@b.c/r'/>")
    presence_waiter.wait

    assert_kind_of(Roster::Helper::RosterItem, cb_item)
    assert_nil(cb_op)
    assert_kind_of(Presence, cb_p)
    assert_nil(cb_p.type)
    assert_equal(true, h['a@b.c'].online?)
    presences = 0
    h['a@b.c'].each_presence { presences += 1 }
    assert_equal(1, presences)
  end

  def test_subscribe
    state { |iq|
      send("<iq type='result' id='#{iq.id}'>
              <query xmlns='jabber:iq:roster'/>
            </iq>")
    }

    query_waiter = Semaphore.new
    h = Roster::Helper::new(@client)
    h.add_query_callback { |iq| query_waiter.run }
    wait_state
    query_waiter.wait

    state { |iq|
      assert_kind_of(Iq, iq)
      assert_equal('jabber:iq:roster', iq.queryns)
      assert_equal(JID.new('contact@example.org'), iq.query.first_element('item').jid)
      assert_equal('MyContact', iq.query.first_element('item').iname)
      send("<iq type='set'>
              <query xmlns='jabber:iq:roster'>
                <item jid='contact@example.org' subscription='none' name='MyContact'/>
              </query>
            </iq>
            <iq type='result' id='#{iq.id}'/>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(:subscribe, pres.type)
      assert_equal(JID.new('contact@example.org'), pres.to)
      Thread.pass
    }
    h.add('contact@example.org', 'MyContact', true)
    wait_state
    query_waiter.wait
    wait_state
  end

  def test_accept_subscription
    state { |iq|
      send("<iq type='result' id='#{iq.id}'>
              <query xmlns='jabber:iq:roster'/>
            </iq>")
    }

    query_waiter = Semaphore.new
    h = Roster::Helper::new(@client)
    h.add_query_callback { |iq| query_waiter.run }
    wait_state
    query_waiter.wait

    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(:subscribed, pres.type)
    }
    state { |iq|
      assert_kind_of(Iq, iq)
      assert_equal(:set, iq.type)
      send("<iq type='result' id='#{iq.id}'/>")
    }

    cb_lock = Semaphore.new
    h.add_subscription_request_callback { |item,pres|
      assert_nil(item)
      assert_kind_of(Presence, pres)
      h.accept_subscription(pres.from)
      cb_lock.run
    }
    send("<presence type='subscribe' from='contact@example.org' to='user@example.com'/>")
    skip_state
    wait_state
    cb_lock.wait

    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(:subscribed, pres.type)
      assert_equal(JID.new('contact@example.org'), pres.to)
    }
    wait_state
  end

  def test_decline_subscription
    state { |iq|
      send("<iq type='result' id='#{iq.id}'>
              <query xmlns='jabber:iq:roster'/>
            </iq>")
    }

    query_waiter = Semaphore.new
    h = Roster::Helper::new(@client)
    h.add_query_callback { |iq| query_waiter.run }
    wait_state
    query_waiter.wait

    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(:unsubscribed, pres.type)
      assert_equal(JID.new('contact@example.org'), pres.to)
    }
    cb_lock = Semaphore.new
    h.add_subscription_request_callback { |item,pres|
      assert_nil(item)
      assert_kind_of(Presence, pres)
      h.decline_subscription(pres.from)

      cb_lock.run
    }

    send("<presence type='subscribe' from='contact@example.org' to='user@example.com'/>")
    wait_state
    cb_lock.wait
  end

  def test_groupset
    state { |iq|
      send("<iq type='result'>
              <query xmlns='jabber:iq:roster'>
                <item jid='test@test' subscription='both'>
                  <group>One</group>
                  <group>Two</group>
                </item>
              </query>
            </iq>")
    }

    query_waiter = Semaphore.new
    h = Roster::Helper.new(@client)
    h.add_query_callback { query_waiter.run }
    wait_state
    query_waiter.wait

    assert_equal(1, h.items.size)
    assert_equal(%w(One Two).sort, h['test@test'].groups.sort)

    state { |iq|
      send("<iq type='result' id='#{iq.id}'>#{iq.query}</iq>")
    }
    h['test@test'].groups = %w(One Two Three)
    h['test@test'].send
    wait_state
    query_waiter.wait
    assert_equal(%w(One Two Three).sort, h['test@test'].groups.sort)
  end

  def test_nameset
    state { |iq|
      send("<iq type='result'>
              <query xmlns='jabber:iq:roster'>
                <item jid='test@test' subscription='both'/>
              </query>
            </iq>")
    }

    query_waiter = Semaphore.new
    h = Roster::Helper.new(@client)
    h.add_query_callback { query_waiter.run }
    wait_state
    query_waiter.wait

    assert_equal(1, h.items.size)
    assert_nil(h['test@test'].iname)

    state { |iq|
      send("<iq type='result' id='#{iq.id}'>#{iq.query}</iq>")
    }
    h['test@test'].iname = 'Unknown'
    h['test@test'].send
    wait_state
    query_waiter.wait
    assert_equal('Unknown', h['test@test'].iname)

    state { |iq|
      send("<iq type='result' id='#{iq.id}'>#{iq.query}</iq>")
    }
    h['test@test'].iname = 'Known'
    h['test@test'].send
    wait_state
    query_waiter.wait
    assert_equal('Known', h['test@test'].iname)

    state { |iq|
      send("<iq type='result' id='#{iq.id}'>#{iq.query}</iq>")
    }
    h['test@test'].iname = nil
    h['test@test'].send
    wait_state
    query_waiter.wait
    assert_nil(h['test@test'].iname)
  end

  def test_update_callback
    update_args = nil
    update_waiter = Semaphore.new

    h = Roster::Helper.new(@client)
    h.add_update_callback { |*a|
      update_args = a
      update_waiter.run
    }

    send("<iq type='set'>
            <query xmlns='jabber:iq:roster'>
              <item jid='foo@bar' name='Foo'/>
            </query>
          </iq>")
    update_waiter.wait
    assert_nil(update_args[0])
    assert_equal(JID.new('foo@bar'), update_args[1].jid)
    assert_equal('Foo', update_args[1].iname)

    send("<iq type='set'>
            <query xmlns='jabber:iq:roster'>
              <item jid='foo@bar'/>
            </query>
          </iq>")
    update_waiter.wait
    assert_equal(JID.new('foo@bar'), update_args[0].jid)
    assert_equal('Foo', update_args[0].iname)
    assert_equal(JID.new('foo@bar'), update_args[1].jid)
    assert_nil(update_args[1].iname)

    send("<iq type='set'>
            <query xmlns='jabber:iq:roster'>
              <item jid='foo@bar' subscription='remove'/>
            </query>
          </iq>")
    update_waiter.wait
    assert_equal(JID.new('foo@bar'), update_args[0].jid)
    assert_nil(update_args[0].iname)
    assert_nil(update_args[1])
  end
end

