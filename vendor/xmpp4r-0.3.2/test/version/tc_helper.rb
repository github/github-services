#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/version/helper/responder'
require 'xmpp4r/version/helper/simpleresponder'
include Jabber

class Version::HelperTest < Test::Unit::TestCase
  include ClientTester

  def test_create
    h = Version::Responder::new(@client)
    assert_kind_of(Version::Responder, h)
    assert_respond_to(h, :add_version_callback)
  end

  def test_callback
    # Prepare helper
    h = Version::Responder::new(@client)

    calls = 0
    h.add_version_callback { |iq,responder|
      calls += 1
      assert('jabber:iq:version', iq.queryns)
      responder.call('Test program', '1.0', 'Ruby Test::Unit')
    }

    # Send stanzas which shouldn't match
    @server.send("<iq type='set'><query xmlns='jabber:iq:version'/></iq>")
    @server.send("<iq type='get'><query xmlns='jabber:iq:browse'/></iq>")
    assert_equal(0, calls)

    # Send a query
    @server.send("<iq type='get'><query xmlns='jabber:iq:version'/></iq>") { |reply|
      assert_equal('Test program', reply.query.iname)
      assert_equal('1.0', reply.query.version)
      assert_equal('Ruby Test::Unit', reply.query.os)
      true
    }
    assert_equal(1, calls)
  end

  def test_simple
    h = Version::SimpleResponder.new(@client, 'Test program', '1.0', 'Ruby Test::Unit')

    # Send a query
    @server.send("<iq type='get'><query xmlns='jabber:iq:version'/></iq>") { |reply|
      assert_equal('Test program', reply.query.iname)
      assert_equal('1.0', reply.query.version)
      assert_equal('Ruby Test::Unit', reply.query.os)
      true
    }

  end
end
