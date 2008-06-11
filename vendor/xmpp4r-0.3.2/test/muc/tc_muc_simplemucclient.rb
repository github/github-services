#!/usr/bin/ruby


$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'
require 'xmpp4r/muc'
require 'xmpp4r/semaphore'
include Jabber

class SimpleMUCClientTest < Test::Unit::TestCase
  include ClientTester

  def test_new1
    m = MUC::SimpleMUCClient.new(@client)
    assert_equal(nil, m.jid)
    assert_equal(nil, m.my_jid)
    assert_equal({}, m.roster)
    assert(!m.active?)
  end

  def test_complex
    m = MUC::SimpleMUCClient.new(@client)

    block_args = []
    wait = Semaphore.new
    block = lambda { |*a| block_args = a; wait.run }
    m.on_room_message(&block)
    m.on_message(&block)
    m.on_private_message(&block)
    m.on_subject(&block)
    m.on_join(&block)
    m.on_leave(&block)
    m.on_self_leave(&block)

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
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    wait_state
    assert(m.active?)
    assert_equal(3, m.roster.size)

    state { |msg|
      assert_kind_of(Message, msg)
      assert_equal(:groupchat, msg.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), msg.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit'), msg.to)
      assert_equal('TestCasing room', msg.subject)
      assert_nil(msg.body)
      send(msg.set_from('darkcave@macbeth.shakespeare.lit/thirdwitch').set_to('hag66@shakespeare.lit/pda'))
    }
    assert_nil(m.subject)
    wait.wait
    m.subject = 'TestCasing room'
    wait_state
    wait.wait
    assert_equal([nil, 'thirdwitch', 'TestCasing room'], block_args)
    assert_equal('TestCasing room', m.subject)
  end

end
