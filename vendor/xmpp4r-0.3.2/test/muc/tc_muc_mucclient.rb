#!/usr/bin/ruby


$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'
require 'xmpp4r/muc'
require 'xmpp4r/semaphore'
include Jabber

class MUCClientTest < Test::Unit::TestCase
  include ClientTester

  def test_new1
    m = MUC::MUCClient.new(@client)
    assert_equal(nil, m.jid)
    assert_equal(nil, m.my_jid)
    assert_equal({}, m.roster)
    assert(!m.active?)
  end

  # JEP-0045: 6.3 Entering a Room
  def test_enter_room
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/thirdwitch'), pres.to)
      send("<presence from='darkcave@macbeth.shakespeare.lit' to='hag66@shakespeare.lit/pda' type='error'>" + 
           "<error code='400' type='modify'>" +
           "<jid-malformed xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>" +
           "</error></presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/thirdwitch'), pres.to)
      send("<presence from='darkcave@macbeth.shakespeare.lit/firstwitch' to='hag66@shakespeare.lit/pda'>" +
          "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='owner' role='moderator'/></x>" +
          "</presence>" +
          "<presence from='darkcave@macbeth.shakespeare.lit/secondwitch' to='hag66@shakespeare.lit/pda'>" +
          "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='admin' role='moderator'/></x>" +
          "</presence>" +
          "<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
          "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
          "</presence>")
    }


    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert(!m.active?)
    assert_nil(m.room)

    assert_raises(ErrorException) {
      m.join('darkcave@macbeth.shakespeare.lit/thirdwitch')
    }
    wait_state
    assert(!m.active?)
    assert_nil(m.room)

    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    wait_state
    assert(m.active?)
    assert_equal('darkcave', m.room)
    assert_equal(3, m.roster.size)
    m.roster.each { |resource,pres|
      assert_equal(resource, pres.from.resource)
      assert_equal('darkcave', pres.from.node)
      assert_equal('macbeth.shakespeare.lit', pres.from.domain)
      assert_kind_of(String, resource)
      assert_kind_of(Presence, pres)
      assert(%w(firstwitch secondwitch thirdwitch).include?(resource))
      assert_kind_of(MUC::XMUCUser, pres.x)
      assert_kind_of(Array, pres.x.items)
      assert_equal(1, pres.x.items.size)
    }
    assert_equal(:owner, m.roster['firstwitch'].x.items[0].affiliation)
    assert_equal(:moderator, m.roster['firstwitch'].x.items[0].role)
    assert_equal(:admin, m.roster['secondwitch'].x.items[0].affiliation)
    assert_equal(:moderator, m.roster['secondwitch'].x.items[0].role)
    assert_equal(:member, m.roster['thirdwitch'].x.items[0].affiliation)
    assert_equal(:participant, m.roster['thirdwitch'].x.items[0].role)
    assert_nil(m.roster['thirdwitch'].x.items[0].jid)

    send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='crone1@shakespeare.lit/desktop'>" +
         "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='none' jid='hag66@shakespeare.lit/pda' role='participant'/></x>" +
         "</presence>")
    sleep 0.1
    assert_equal(3, m.roster.size)
    assert_equal(:none, m.roster['thirdwitch'].x.items[0].affiliation)
    assert_equal(:participant, m.roster['thirdwitch'].x.items[0].role)
    assert_equal(JID.new('hag66@shakespeare.lit/pda'), m.roster['thirdwitch'].x.items[0].jid)
  end

  def test_enter_room_password
    state { |pres|
      assert_kind_of(Presence, pres)
      send("<presence from='darkcave@macbeth.shakespeare.lit' to='hag66@shakespeare.lit/pda' type='error'>" +
           "<error code='401' type='auth'><not-authorized xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error>" +
           "</presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal('cauldron', pres.x.password)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_raises(ErrorException) {
      m.join('darkcave@macbeth.shakespeare.lit/thirdwitch')
    }
    wait_state
    assert(!m.active?)

    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch', 'cauldron'))
    wait_state
    assert(m.active?)
  end

  def test_members_only_room
    state { |pres|
      assert_kind_of(Presence, pres)
      send("<presence from='darkcave@macbeth.shakespeare.lit' to='hag66@shakespeare.lit/pda' type='error'>" +
           "<error code='407' type='auth'><registration-required xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error>" +
           "</presence>")
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_raises(ErrorException) {
      m.join('darkcave@macbeth.shakespeare.lit/thirdwitch')
    }
    assert(!m.active?)

    wait_state
  end

  def test_banned_users
    state { |pres|
      assert_kind_of(Presence, pres)
      send("<presence from='darkcave@macbeth.shakespeare.lit' to='hag66@shakespeare.lit/pda' type='error'>" +
           "<error code='403' type='auth'><forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error>" +
           "</presence>")
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_raises(ErrorException) {
      m.join('darkcave@macbeth.shakespeare.lit/thirdwitch')
    }
    assert(!m.active?)

    wait_state
  end

  def test_nickname_conflict
    state { |pres|
      assert_kind_of(Presence, pres)
      send("<presence from='darkcave@macbeth.shakespeare.lit' to='hag66@shakespeare.lit/pda' type='error'>" +
           "<error code='409' type='cancel'><conflict xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error>" +
           "</presence>")
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_raises(ErrorException) {
      m.join('darkcave@macbeth.shakespeare.lit/thirdwitch')
    }
    assert(!m.active?)

    wait_state
  end

  def test_max_users
    state { |pres|
      assert_kind_of(Presence, pres)
      send("<presence from='darkcave@macbeth.shakespeare.lit' to='hag66@shakespeare.lit/pda' type='error'>" +
           "<error code='503' type='wait'><service-unavailable xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error>" +
           "</presence>")
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_raises(ErrorException) {
      m.join('darkcave@macbeth.shakespeare.lit/thirdwitch')
    }
    assert(!m.active?)

    wait_state
  end

  def test_locked_room
    state { |pres|
      send("<presence from='darkcave@macbeth.shakespeare.lit' to='hag66@shakespeare.lit/pda' type='error'>" + 
           "<error code='404' type='cancel'><item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error>" +
           "</presence>")
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_raises(ErrorException) {
      m.join('darkcave@macbeth.shakespeare.lit/thirdwitch')
    }
    assert(!m.active?)
    wait_state
  end

  def test_exit_room
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_nil(pres.type)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(:unavailable, pres.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_nil(pres.status)
      send("<presence from='darkcave@macbeth.shakespeare.lit/secondwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda' type='unavailable'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='none'/></x>" +
           "</presence>")
    }

    ignored_stanzas = 0
    @client.add_stanza_callback { |stanza|
      ignored_stanzas += 1
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_equal(0, ignored_stanzas)
    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    wait_state
    assert(m.active?)

    assert_equal(0, ignored_stanzas)
    assert_equal(m, m.exit)
    wait_state
    assert(!m.active?)
    assert_equal(1, ignored_stanzas)
  end

  def test_custom_exit_message
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_nil(pres.type)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(:unavailable, pres.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal('gone where the goblins go', pres.status)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda' type='unavailable'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='none'/></x>" +
           "</presence>")
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    assert(m.active?)
    wait_state

    assert_equal(m, m.exit('gone where the goblins go'))
    assert(!m.active?)
    wait_state
  end

  def test_joins
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_nil(pres.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/thirdwitch'), pres.to)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(:unavailable, pres.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/thirdwitch'), pres.to)
      assert_nil(pres.status)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda' type='unavailable'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='none'/></x>" +
           "</presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_nil(pres.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/fourthwitch'), pres.to)
      send("<presence from='darkcave@macbeth.shakespeare.lit/fourthwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(:unavailable, pres.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/fourthwitch'), pres.to)
      assert_equal(pres.status, 'Exiting one last time')
      send("<presence from='darkcave@macbeth.shakespeare.lit/fourthwitch' to='hag66@shakespeare.lit/pda' type='unavailable'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='none'/></x>" +
           "</presence>")
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    wait_state
    assert(m.active?)

    assert_raises(RuntimeError) { m.join('darkcave@macbeth.shakespeare.lit/thirdwitch') }
    assert_raises(RuntimeError) { m.join('darkcave@macbeth.shakespeare.lit/fourthwitch') }
    assert(m.active?)

    assert_equal(m, m.exit)
    wait_state
    assert(!m.active?)
    assert_raises(RuntimeError) { m.exit }
    assert(!m.active?)

    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/fourthwitch'))
    wait_state
    assert(m.active?)

    assert_raises(RuntimeError) { m.join('darkcave@macbeth.shakespeare.lit/thirdwitch') }
    assert_raises(RuntimeError) { m.join('darkcave@macbeth.shakespeare.lit/fourthwitch') }
    assert(m.active?)

    assert_equal(m, m.exit('Exiting one last time'))
    wait_state
    assert(!m.active?)
    assert_raises(RuntimeError) { m.exit }
    assert(!m.active?)
  end

  def test_message_callback
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal('cauldron', pres.x.password)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
    }

    message_lock = Semaphore.new

    messages_client = 0
    @client.add_message_callback { |msg|
      messages_client += 1
      message_lock.run
    }
    
    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    messages_muc = 0
    m.add_message_callback { |msg|
      messages_muc += 1
      message_lock.run
    }
    messages_muc_private = 0
    m.add_private_message_callback { |msg|
      messages_muc_private += 1
      message_lock.run
    }

    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch', 'cauldron'))
    assert(m.active?)

    assert_equal(0, messages_client)
    assert_equal(0, messages_muc)
    assert_equal(0, messages_muc_private)

    send("<message from='darkcave@macbeth.shakespeare.lit/firstwitch' to='hag66@shakespeare.lit/pda'><body>Hello</body></message>")
    message_lock.wait

    assert_equal(0, messages_client)
    assert_equal(1, messages_muc)
    assert_equal(0, messages_muc_private)

    send("<message from='user@domain/resource' to='hag66@shakespeare.lit/pda'><body>Hello</body></message>")
    message_lock.wait

    assert_equal(1, messages_client)
    assert_equal(1, messages_muc)
    assert_equal(0, messages_muc_private)

    send("<message type='chat' from='darkcave@macbeth.shakespeare.lit/firstwitch' to='hag66@shakespeare.lit/pda'><body>Hello</body></message>")
    message_lock.wait

    assert_equal(1, messages_client)
    assert_equal(1, messages_muc)
    assert_equal(1, messages_muc_private)

    wait_state
   end

  def test_presence_callbacks
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_nil(pres.x.password)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
    }

    presence_lock = Semaphore.new

    presences_client = 0
    @client.add_presence_callback { |pres|
      presences_client += 1
      presence_lock.run
    }   
    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    presences_join = 0
    m.add_join_callback { |pres|
      presences_join += 1
      presence_lock.run
    }
    presences_leave = 0
    m.add_leave_callback { |pres|
      presences_leave += 1
      presence_lock.run
    }
    presences_muc = 0
    m.add_presence_callback { |pres|
      presences_muc += 1
      presence_lock.run
    }

    assert_equal(0, presences_client)
    assert_equal(0, presences_join)
    assert_equal(0, presences_leave)
    assert_equal(0, presences_muc)

    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    assert(m.active?)

    assert_equal(0, presences_client)
    assert_equal(0, presences_join) # Joins before own join won't be called back
    assert_equal(0, presences_leave)
    assert_equal(0, presences_muc)

    send("<presence from='darkcave@macbeth.shakespeare.lit/firstwitch' to='hag66@shakespeare.lit/pda'>" +
         "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
         "</presence>")
    presence_lock.wait
    assert_equal(0, presences_client)
    assert_equal(1, presences_join)
    assert_equal(0, presences_leave)
    assert_equal(0, presences_muc)

    send("<presence from='user@domain/resource' to='hag66@shakespeare.lit/pda'>" +
         "<show>chat</show>" +
         "</presence>")
    presence_lock.wait
    assert_equal(1, presences_client)
    assert_equal(1, presences_join)
    assert_equal(0, presences_leave)
    assert_equal(0, presences_muc)

    send("<presence from='darkcave@macbeth.shakespeare.lit/firstwitch' to='hag66@shakespeare.lit/pda'>" +
         "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
         "<show>away</show></presence>")
    presence_lock.wait
    assert_equal(1, presences_client)
    assert_equal(1, presences_join)
    assert_equal(0, presences_leave)
    assert_equal(1, presences_muc)

    send("<presence from='darkcave@macbeth.shakespeare.lit/firstwitch' to='hag66@shakespeare.lit/pda' type='unavailable'/>")
    presence_lock.wait
    assert_equal(1, presences_client)
    assert_equal(1, presences_join)
    assert_equal(1, presences_leave)
    assert_equal(1, presences_muc)
    wait_state
  end

  def test_send
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_nil(pres.x.password)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
    }
    state { |stanza|
      assert_kind_of(Message, stanza)
      assert(:groupchat, stanza.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), stanza.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit'), stanza.to)
      assert_equal('First message', stanza.body)
    }
    state { |stanza|
      assert_kind_of(Message, stanza)
      assert(:chat, stanza.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), stanza.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/secondwitch'), stanza.to)
      assert_equal('Second message', stanza.body)
    }
    state { |stanza|
      assert_kind_of(Message, stanza)
      assert(:chat, stanza.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), stanza.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/firstwitch'), stanza.to)
      assert_equal('Third message', stanza.body)
    }
    
    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'

    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    wait_state
    assert(m.active?)

    m.send(Jabber::Message.new(nil, 'First message'))
    wait_state
    m.send(Jabber::Message.new(nil, 'Second message'), 'secondwitch')
    wait_state
    m.send(Jabber::Message.new('secondwitch', 'Third message'), 'firstwitch')
    wait_state
  end

  def test_nick
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_nil(pres.x.password)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
           "</presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/secondwitch'), pres.to)
      assert_nil(pres.type)
      send("<presence from='darkcave@macbeth.shakespeare.lit' to='hag66@shakespeare.lit/pda' type='error'>" +
           "<error code='409' type='cancel'><conflict xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error>" +
           "</presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/oldhag'), pres.to)
      assert_nil(pres.type)
      send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda' type='unavailable'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'>" +
           "<item affiliation='member' jid='hag66@shakespeare.lit/pda' nick='oldhag' role='participant'/>" +
           "<status code='303'/>" +
           "</x></presence>" +
           "<presence from='darkcave@macbeth.shakespeare.lit/oldhag' to='hag66@shakespeare.lit/pda'>" +
           "<x xmlns='http://jabber.org/protocol/muc#user'>" +
           "<item affiliation='member' jid='hag66@shakespeare.lit/pda' role='participant'/>" +
           "</x></presence>")
    }

    m = MUC::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'

    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    wait_state
    assert(m.active?)
    assert_equal('thirdwitch', m.nick)

    assert_raises(ErrorException) {
      m.nick = 'secondwitch'
    }
    wait_state
    assert(m.active?)
    assert_equal('thirdwitch', m.nick)

    m.nick = 'oldhag'
    wait_state
    assert(m.active?)
    assert_equal('oldhag', m.nick)
  end
end
