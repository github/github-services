#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/idgenerator'
include Jabber

class IdGeneratorTest < Test::Unit::TestCase
  def test_instances
    assert_equal(Jabber::IdGenerator.instance, Jabber::IdGenerator.instance)
  end

  def test_unique
    ids = []
    100.times { ids.push(Jabber::IdGenerator.generate_id) }

    ok = true
    ids.each_index { |a|
      ids.each_index { |b|
        if a == b
          ok = false if ids[a] != ids[b]
        else
          ok = false if ids[a] == ids[b]
        end
      }
    }
    assert(ok)
  end
end
