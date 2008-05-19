#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/pubsub/helper/servicehelper'
include Jabber


class PubSub::ServiceHelperTest < Test::Unit::TestCase
  include ClientTester

  def test_create
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    assert_kind_of(PubSub::ServiceHelper, h)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('create', iq.pubsub.children.first.name)
      assert_equal('mynode', iq.pubsub.children.first.attributes['node'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <create node='#{iq.pubsub.children.first.attributes['node']}'/>
              </pubsub>
            </iq>")
    }
    assert_equal('mynode', h.create('mynode'))
    wait_state
  end

  def test_delete
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('delete', iq.pubsub.children.first.name)
      assert_equal('mynode', iq.pubsub.children.first.attributes['node'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    h.delete('mynode')
    wait_state
  end

  def test_publish
    item1 = Jabber::PubSub::Item.new
    item1.text = 'foobar'
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('publish', iq.pubsub.children[0].name)
      assert_equal(1, iq.pubsub.children[0].children.size)
      assert_equal('item', iq.pubsub.children[0].children[0].name)
      assert_nil(iq.pubsub.children[0].children[0].attributes['id'])
      assert_equal(1, iq.pubsub.children[0].children[0].children.size)
      assert_equal(item1.children.to_s, iq.pubsub.children[0].children[0].children[0].to_s)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    h.publish('mynode', item1)
    wait_state
  end

  def test_items
    item1 = Jabber::PubSub::Item.new("1")
    item1.text = 'foobar'
    item2 = Jabber::PubSub::Item.new("2")
    item2.text = 'barfoo'

    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('items', iq.pubsub.children.first.name)
      assert_equal('mynode', iq.pubsub.children.first.attributes['node'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <items node='mynode'>
                  #{item1.to_s}
                  #{item2.to_s}
                </items>
              </pubsub>
            </iq>")
    }

    items = h.items('mynode')
    assert_equal(2, items.size)
    assert_kind_of(REXML::Text, items['1'])
    assert_kind_of(REXML::Text, items['2'])
    assert_equal(item1.children.to_s, items['1'].to_s)
    assert_equal(item2.children.to_s, items['2'].to_s)
    wait_state
  end

  def test_affiliations
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('affiliations', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub'>
               <affiliations>
                  <affiliation node='node1' affiliation='owner'/>
                  <affiliation node='node2' affiliation='publisher'/>
                  <affiliation node='node5' affiliation='outcast'/>
                  <affiliation node='node6' affiliation='owner'/>
                </affiliations>
              </pubsub>
            </iq>")
    }

    a = h.affiliations
    assert_kind_of(Hash, a)
    assert_equal(4, a.size)
    assert_equal(:owner, a['node1'])
    assert_equal(:publisher, a['node2'])
    assert_equal(:outcast, a['node5'])
    assert_equal(:owner, a['node6'])
    wait_state
  end

  def test_subscriptions
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscriptions', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>
                <subscriptions node='princely_musings'>
                  <subscription jid='hamlet@denmark.lit' subscription='subscribed'/>
                  <subscription jid='polonius@denmark.lit' subscription='unconfigured'/>
                  <subscription jid='bernardo@denmark.lit' subscription='subscribed' subid='123-abc'/>
                  <subscription jid='bernardo@denmark.lit' subscription='subscribed' subid='004-yyy'/>
                </subscriptions>
              </pubsub>
            </iq>")
    }

    s = h.subscriptions('mynode')
    assert_kind_of(Array,s)
    assert_equal(4,s.size)
    assert_kind_of(REXML::Element,s[0])
    assert_kind_of(REXML::Element,s[1])
    assert_kind_of(REXML::Element,s[2])
    assert_kind_of(REXML::Element,s[3])
    wait_state
  end

  def test_get_all_subscriptions
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscriptions', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
            <pubsub xmlns='http://jabber.org/protocol/pubsub'>
	        <subscriptions>
		  <subscription node='node1' jid='francisco@denmark.lit' subscription='subscribed'/>
		  <subscription node='node2' jid='francisco@denmark.lit' subscription='subscribed'/>
		  <subscription node='node5' jid='francisco@denmark.lit' subscription='unconfigured'/>
		  <subscription node='node6' jid='francisco@denmark.lit' subscription='pending'/>
		</subscriptions>
	     </pubsub>
	     </iq>")
    }

    s = h.subscriptions
    assert_kind_of(Array,s)
    assert_equal(4,s.size)
    assert_kind_of(REXML::Element,s[0])
    assert_kind_of(REXML::Element,s[1])
    assert_kind_of(REXML::Element,s[2])
    assert_kind_of(REXML::Element,s[3])
    wait_state
  end

  def test_subscribers
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscriptions', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
            <pubsub xmlns='http://jabber.org/protocol/pubsub'>
	        <subscriptions node='princely_musings'>
		  <subscription jid='peter@denmark.lit' subscription='subscribed'/>
		  <subscription jid='frank@denmark.lit' subscription='subscribed'/>
		  <subscription jid='albrecht@denmark.lit' subscription='unconfigured'/>
		  <subscription jid='hugo@denmark.lit' subscription='pending'/>
		</subscriptions>
	     </pubsub>
	     </iq>")
    }

    s = h.subscribers('princely_musings')
    assert_equal(4,s.size)
    assert_kind_of(String,s[0])
    assert_kind_of(String,s[1])
    assert_kind_of(String,s[2])
    assert_kind_of(String,s[3])
    wait_state
  end
end
