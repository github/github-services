#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/iq'
include Jabber

class IqTest < Test::Unit::TestCase
  def test_create
    x = Iq::new()
    assert_equal("iq", x.name)
    assert_equal("jabber:client", x.namespace)
    assert_equal("<iq xmlns='jabber:client'/>", x.to_s)
  end

  def test_iqauth
    x = Iq::new_authset(JID::new('node@domain/resource'), 'password')
    assert_equal("<iq type='set' xmlns='jabber:client'><query xmlns='jabber:iq:auth'><username>node</username><password>password</password><resource>resource</resource></query></iq>", x.to_s)
  end

  def test_iqauth_digest
    x = Iq::new_authset_digest(JID::new('node@domain/resource'), '', 'password')
    assert_equal("<iq type='set' xmlns='jabber:client'><query xmlns='jabber:iq:auth'><username>node</username><digest>#{Digest::SHA1.hexdigest('password')}</digest><resource>resource</resource></query></iq>", x.to_s)
  end

  def test_register
    x1 = Iq::new_register
    assert_equal("<iq type='set' xmlns='jabber:client'><query xmlns='jabber:iq:register'/></iq>", x1.to_s)
    x2 = Iq::new_register('node')
    assert_equal("<iq type='set' xmlns='jabber:client'><query xmlns='jabber:iq:register'><username>node</username></query></iq>", x2.to_s)
    x3 = Iq::new_register('node', 'password')
    assert_equal("<iq type='set' xmlns='jabber:client'><query xmlns='jabber:iq:register'><username>node</username><password>password</password></query></iq>", x3.to_s)
  end

  def test_rosterget
    x = Iq::new_rosterget
    assert_equal("<iq type='get' xmlns='jabber:client'><query xmlns='jabber:iq:roster'/></iq>", x.to_s)
  end

  def test_rosterset
    x = Iq::new_rosterset
    assert_equal("<iq type='set' xmlns='jabber:client'><query xmlns='jabber:iq:roster'/></iq>", x.to_s)
  end

  def test_browseget
    x = Iq::new_browseget
    assert_equal("<iq type='get' xmlns='jabber:client'><query xmlns='jabber:iq:browse'/></iq>", x.to_s)
  end

  def test_types
    iq = Iq::new
    assert_equal(nil, iq.type)
    iq.type = :get
    assert_equal(:get, iq.type)
    iq.type = :set
    assert_equal(:set, iq.type)
    iq.type = :result
    assert_equal(:result, iq.type)
    iq.type = :error
    assert_equal(:error, iq.type)
    iq.type = :invalid
    assert_equal(nil, iq.type)
  end

  def test_query
    x = Iq::new(:set)
    assert_equal(nil, x.queryns)
    query = REXML::Element::new('query')
    x.add(query)
    assert_equal('jabber:client', x.queryns)
    query.add_namespace('jabber:iq:auth')
    assert_equal(query.to_s, x.query.to_s)
    assert_equal('jabber:iq:auth', x.queryns)

    query2 = REXML::Element::new('query')
    x.query = query2
    assert_equal('jabber:client', x.queryns)
    query2.add_namespace('jabber:iq:register')
    assert_equal('jabber:iq:register', x.queryns)
  end

  def test_vcard
    x = Iq::new
    assert_equal(nil, x.vcard)
    x.add(vcard = REXML::Element.new('vCard'))
    assert_equal(vcard, x.vcard)
  end

  def test_error
    x = Iq::new(:set)
    e = REXML::Element::new('error')
    x.add(e)
    # test if, after an import, the error element is successfully changed
    # into an Error object.
    x2 = Iq::new.import(x)
    assert_equal(Error, x2.first_element('error').class)
  end

  def test_new_query
    x = Iq::new_query(:get, JID.new('a@b/c'))
    assert_equal(:get, x.type)
    assert_equal(nil, x.from)
    assert_equal(JID.new('a@b/c'), x.to)
    assert_kind_of(IqQuery, x.query)
    assert_equal('jabber:client', x.queryns)
  end
end
