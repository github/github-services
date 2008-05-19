#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/vcard/helper/vcard'
include Jabber

class Vcard::HelperTest < Test::Unit::TestCase
  include ClientTester

  def test_create
    h = Vcard::Helper::new(@client)
    assert_kind_of(Vcard::Helper, h)
  end

  def test_callback
    @server.on_exception{|*e| p e}
    class << @client
      def jid
        JID.new('b@b.com/b')
      end
    end

    state { |iq|
      assert_kind_of(Iq, iq)
      assert_equal(JID.new('a@b.com'), iq.to)
      assert_equal(:get, iq.type)
      assert_nil(iq.queryns)
      assert_kind_of(Vcard::IqVcard, iq.vcard)
      children = 0
      iq.vcard.each_child { children += 1 }
      assert_equal(0, children)

      send("<iq type='result' from='#{iq.to}' to='#{iq.from}' id='#{iq.id}'><vCard xmlns='vcard-temp'><NICKNAME>Mr. B</NICKNAME><PHOTO><TYPE>image/png</TYPE><BINVAL>====</BINVAL></PHOTO></vCard></iq>")
    }

    res = Vcard::Helper::get(@client, 'a@b.com')
    wait_state
    assert_kind_of(Vcard::IqVcard, res)
    assert_equal('Mr. B', res['NICKNAME'])
    assert_equal('image/png', res['PHOTO/TYPE'])
    assert_equal('====', res['PHOTO/BINVAL'])
  end
end

