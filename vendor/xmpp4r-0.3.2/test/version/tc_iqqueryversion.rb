#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/iq'
require 'xmpp4r/version/iq/version'
include Jabber

class Version::IqQueryVersionTest < Test::Unit::TestCase
  def test_create_empty
    x = Version::IqQueryVersion::new
    assert_equal('jabber:iq:version', x.namespace)
    assert_nil(x.iname)
    assert_nil(x.version)
    assert_nil(x.os)
  end

  def test_create
    x = Version::IqQueryVersion::new('my test', 'XP')
    assert_equal('jabber:iq:version', x.namespace)
    assert_equal('my test', x.iname)
    assert_equal('XP', x.version)
    assert_equal(nil, x.os)
  end

  def test_create_with_os
    x = Version::IqQueryVersion::new('superbot', '1.0-final', 'FreeBSD 5.4-RELEASE-p4')
    assert_equal('jabber:iq:version', x.namespace)
    assert_equal('superbot', x.iname)
    assert_equal('1.0-final', x.version)
    assert_equal('FreeBSD 5.4-RELEASE-p4', x.os)
  end

  def test_import1
    iq = Iq::new
    q = REXML::Element::new('query')
    q.add_namespace('jabber:iq:version')
    iq.add(q)
    iq2 = Iq::new.import(iq)
    assert_equal(Version::IqQueryVersion, iq2.query.class)
  end

  def test_import2
    iq = Iq::new
    q = REXML::Element::new('query')
    q.add_namespace('jabber:iq:version')
    q.add_element('name').text = 'AstroBot'
    q.add_element('version').text = 'XP'
    q.add_element('os').text = 'FreeDOS'
    iq.add(q)
    iq = Iq::new.import(iq)
    assert_equal(Version::IqQueryVersion, iq.query.class)
    assert_equal('AstroBot', iq.query.iname)
    assert_equal('XP', iq.query.version)
    assert_equal('FreeDOS', iq.query.os)
  end

  def test_replace
    x = Version::IqQueryVersion::new('name', 'version', 'os')

    num = 0
    x.each_element('name') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('version') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('os') { |e| num += 1 }
    assert_equal(1, num)

    x.set_iname('N').set_version('V').set_os('O')

    num = 0
    x.each_element('name') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('version') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('os') { |e| num += 1 }
    assert_equal(1, num)

    x.set_iname(nil).set_version(nil).set_os(nil)

    num = 0
    x.each_element('name') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('version') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('os') { |e| num += 1 }
    assert_equal(0, num)
  end
end
