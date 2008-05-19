#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/jid'
include Jabber

class JIDTest < Test::Unit::TestCase
  def test_create1
    j = JID::new('a', 'b', 'c')
    assert_equal('a', j.node)
    assert_equal('b', j.domain)
    assert_equal('c', j.resource)
  end

  def test_create2
    j = JID::new('a', 'b', 'c')
    j2 = JID::new(j)
    assert_equal('a', j2.node)
    assert_equal('b', j2.domain)
    assert_equal('c', j2.resource)
    assert_equal('a@b/c', j.to_s)
  end

  def test_create3
    j = JID::new('a@b/c')
    assert_equal('a', j.node)
    assert_equal('b', j.domain)
    assert_equal('c', j.resource)
    assert_equal('a@b/c', j.to_s)
  end

  def test_create4
    j = JID::new('a@b')
    assert_equal('a', j.node)
    assert_equal('b', j.domain)
    assert_equal(nil, j.resource)
    assert_equal('a@b', j.to_s)
  end

  def test_create5
    j = JID::new
    assert_equal(nil, j.node)
    assert_equal(nil, j.domain)
    assert_equal(nil, j.resource)
    assert_equal('', j.to_s)
  end

  def test_create6
    j = JID::new('dom')
    assert_equal(nil, j.node)
    assert_equal('dom', j.domain)
    assert_equal(nil, j.resource)
    assert_equal('dom', j.to_s)
  end

  def test_create7
    j = JID::new('dom/res')
    assert_equal(nil, j.node)
    assert_equal('dom', j.domain)
    assert_equal('res', j.resource)
    assert_equal('dom/res', j.to_s)
  end

  def test_create8
    j = JID::new('dom/a@b')
    assert_equal(nil, j.node)
    assert_equal('dom', j.domain)
    assert_equal('a@b', j.resource)
    assert_equal('dom/a@b', j.to_s)
  end

  def test_create9
    assert_nothing_raised { JID::new("#{'n'*1023}@#{'d'*1023}/#{'r'*1023}") }
    assert_raises(ArgumentError) { JID::new("#{'n'*1024}@#{'d'*1023}/#{'r'*1023}") }
    assert_raises(ArgumentError) { JID::new("#{'n'*1023}@#{'d'*1024}/#{'r'*1023}") }
    assert_raises(ArgumentError) { JID::new("#{'n'*1023}@#{'d'*1023}/#{'r'*1024}") }
  end

  def test_create10
    j = JID::new('@b/c')
    assert_equal('', j.node)
    assert_equal('b', j.domain)
    assert_equal('c', j.resource)
    assert_equal('@b/c', j.to_s)
  end

  def test_create11
    j = JID::new('@b')
    assert_equal('', j.node)
    assert_equal('b', j.domain)
    assert_equal(nil, j.resource)
    assert_equal('@b', j.to_s)
  end

  def test_create12
    j = JID::new('@b/')
    assert_equal('', j.node)
    assert_equal('b', j.domain)
    assert_equal('', j.resource)
    assert_equal('@b/', j.to_s)
  end

  def test_create13
    j = JID::new('a@b/')
    assert_equal('a', j.node)
    assert_equal('b', j.domain)
    assert_equal('', j.resource)
    assert_equal('a@b/', j.to_s)
  end

  def test_create14
    j = JID::new('nOdE@dOmAiN/rEsOuRcE')
    assert_equal('node', j.node)
    assert_equal('domain', j.domain)
    assert_equal('rEsOuRcE', j.resource)
    assert_equal('node@domain/rEsOuRcE', j.to_s)
  end

  def test_tos
    assert_equal('', JID::new.to_s)
    assert_equal('domain.fr', JID::new('domain.fr').to_s)
    assert_equal('l@domain.fr', JID::new('l','domain.fr').to_s)
    assert_equal('l@domain.fr/res', JID::new('l','domain.fr','res').to_s)
    assert_equal('domain.fr/res', JID::new(nil,'domain.fr','res').to_s)
  end

  def test_equal
    assert_equal(JID::new('domain.fr'), JID::new('domain.fr'))
    assert_equal(JID::new('domain.fr'), JID::new(nil, 'domain.fr'))
    assert_equal(JID::new('l@domain.fr'), JID::new('l@domain.fr'))
    assert_equal(JID::new('l@domain.fr'), JID::new('l', 'domain.fr'))
    assert_equal(JID::new('l@domain.fr/res'), JID::new('l@domain.fr/res'))
    assert_equal(JID::new('l@domain.fr/res'), JID::new('l', 'domain.fr', 'res'))
  end

  def test_hash
    h = {}
    j = JID::new('l@domain.fr/res')
    h[j] = 'a'
    assert_equal(h[j], h[JID::new('l@domain.fr/res')])
  end

  def test_strip
    assert_equal(JID::new('l@domain.fr'), JID::new('l@domain.fr/res').strip)
    assert_equal(JID::new('l@domain.fr'), JID::new('l@domain.fr').strip)
    assert_equal(JID::new('l@domain.fr'), JID::new('l@domain.fr/res').bare)
    jid = JID::new('l@domain.fr/res')
    jid.strip!
    assert_equal(JID::new('l@domain.fr'), jid)

    jid = JID::new('l@domain.fr/res')
    jid.bare!
    assert_equal(JID::new('l@domain.fr'), jid)
  end

  def test_change1
    j = JID::new('a@b/c')
    j.node = 'd'
    assert_equal('d@b/c', j.to_s)
    j.domain = 'e'
    assert_equal('d@e/c', j.to_s)
    j.resource = 'f'
    assert_equal('d@e/f', j.to_s)
  end

  def test_escaping
    j = JID::new('user1@server1')
    j2 = JID::new(JID::escape(j), 'server2', 'res2')
    assert_equal('user1%server1@server2/res2', j2.to_s)
  end

if defined?(libidnbug) # this crashes the interpreter
  def test_invalidnode
#    assert_raises(IDN::Stringprep::StringprepError) { JID::new('toto@a/a', 'server', 'res') }
    assert_raises(IDN::Stringprep::StringprepError) { IDN::Stringprep.nodeprep('toto@a/a') }
  end
end

  def test_empty
    assert(JID.new.empty?)
    assert(!JID.new("test").empty?)
  end

  def test_stripped
    assert(JID.new("node@domain").stripped?)
    assert(!JID.new("node@domain/res").stripped?)
    assert(JID.new("node@domain").bared?)
    assert(!JID.new("node@domain/res").bared?)
  end

  def test_sort
    assert_equal(-1, JID.new('a@b') <=> JID.new('b@b'))
    assert_equal(0, JID.new('a@b') <=> JID.new('a@b'))
    assert_equal(1, JID.new('a@b/r') <=> JID.new('a@b'))

    jids = [JID.new('b@b'), JID.new('a@b/r'), JID.new('a@b')]
    jids.sort!
    assert_equal([JID.new('a@b'), JID.new('a@b/r'), JID.new('b@b')], jids)
  end
end
