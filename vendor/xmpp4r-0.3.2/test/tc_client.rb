#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/client'
include Jabber

class ClientTest < Test::Unit::TestCase
  def test_client1
=begin
    c = Client::new(JID::new('client1@localhost/res'))
    assert_nothing_raised("Couldn't connect") {
      c.connect
    }
    assert_nothing_raised("Couldn't authenticate") {
      c.auth('pw')
    }
=end
  end

  def test_jid_is_jid
    c1 = Client::new(JID::new('user@host/resource'))
    assert_kind_of(JID, c1.jid)
    assert_equal('user@host/resource', c1.jid.to_s)
    c2 = Client::new('user@host/resource')
    assert_kind_of(JID, c2.jid)
    assert_equal('user@host/resource', c2.jid.to_s)
  end
end
