#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/callbacks'
include Jabber

class CallbacksTest < Test::Unit::TestCase
  def test_test1
    called = 0
    cb = Callback::new(5, "toto", Proc::new { called += 1 })
    assert_equal(5, cb.priority)
    assert_equal("toto", cb.ref)
    cb.block.call
    assert_equal(1, called)
    cb.block.call
    assert_equal(2, called)
  end

  def test_callbacklist1
    cbl = CallbackList::new
    called1 = false
    called2 = false
    called3 = false
    called4 = false
    cbl.add(5, "ref1") { called1 = true ; true }
    cbl.add(7, "ref1") { |e| called2 = true ; false}
    cbl.add(9, "ref1") { called3 = true ;false }
    cbl.add(11, "ref1") { called4 = true ; false }
    o = "aaaa"
    assert(cbl.process(o))
    assert(called1)
    assert(called2)
    assert(called3)
    assert(called4)
  end

  def test_callbacklist2
    cbl = CallbackList::new
    assert(0, cbl.length)
    cbl.add(5, "ref1") { called1 = true }
    assert(1, cbl.length)
    cbl.add(7, "ref2") { |e| called2 = true ; e.consume }
    assert(2, cbl.length)
    cbl.delete("ref2")
    assert(1, cbl.length)
    cbl.add(9, "ref3") { called3 = true }
    assert(2, cbl.length)
  end

  def test_callbacklist4
    cbl = CallbackList::new
    cbl.add(5, "ref1") { false }
    cbl.add(7, "ref1") { false }
    o = "o"
    assert(!cbl.process(o))
   end

  def test_callbacklist5
    cbl = CallbackList::new
    cbl.add(5, "ref1") { true }
    cbl.add(7, "ref1") { false }
    o = "o"
    assert(cbl.process(o))
   end

  def test_callbacklist6
    cbl = CallbackList::new
    ok = false
    c = 'a'
    d = 'b'
    cbl.add(5, "ref1") { |a, b|
      if a == 'a' and b == 'b'
        ok = true
      end
      false
    }
    assert(!cbl.process(c, d))
    assert(ok)
   end

  def test_callbacklist7
    cbl = CallbackList::new
    called1 = false
    called2 = false
    called3 = false
    called4 = false
    cbl.add(3, "ref1") { called4 = true ; true }
    cbl.add(5, "ref1") { called1 = true ; true }
    cbl.add(7, "ref1") { called2 = true ; 'a'}
    cbl.add(9, "ref1") { called3 = true ;1 }
    o = "aaaa"
    assert(cbl.process(o))
    assert(called1)
    assert(called2)
    assert(called3)
    assert(!called4)
  end

  def test_nested
    cbl = CallbackList.new
    called_outer = 0
    called_inner = 0

    cbl.add(100, nil) {
      called_outer += 1

      if called_outer == 1
        cbl.add(200, nil) {
          called_inner += 1
        }
      end
    }

    assert_equal(0, called_inner)
    assert_equal(0, called_outer)

    cbl.process

    assert_equal(0, called_inner)
    assert_equal(1, called_outer)

    cbl.process

    assert_equal(1, called_inner)
    assert_equal(2, called_outer)
  end
end
