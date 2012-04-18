require File.expand_path('../helper', __FILE__)
require 'stringio'

class JabberTest < Service::TestCase
  class FakeJabber
    class Client
      attr_reader :conference
      def initialize(conference)
        @conference = conference
      end
    end

    attr_accessor :accept_subscriptions
    attr_reader :delivered

    def initialize
      @delivered = []
    end

    def deliver_deferred(*args)
      @delivered << args
    end
  end

  def test_push
    svc = service({'user' => 'a,b , c , b', 'muc' => 'e,f , g, f'}, payload)
    svc.im = FakeJabber.new
    svc.receive_push

    assert svc.im.accept_subscriptions

    assert msg = svc.im.delivered.shift
    assert_equal 'a', msg[0]
    assert_equal :chat, msg[2]

    assert msg = svc.im.delivered.shift
    assert_equal 'b', msg[0]
    assert_equal :chat, msg[2]

    assert msg = svc.im.delivered.shift
    assert_equal 'c', msg[0]
    assert_equal :chat, msg[2]

    assert msg = svc.im.delivered.shift
    assert_equal 'e', msg[0]
    assert_equal :groupchat, msg[2]

    assert msg = svc.im.delivered.shift
    assert_equal 'f', msg[0]
    assert_equal :groupchat, msg[2]

    assert msg = svc.im.delivered.shift
    assert_equal 'g', msg[0]
    assert_equal :groupchat, msg[2]

    assert_nil svc.im.delivered.shift
  end

  def service(*args)
    super Service::Jabber, *args
  end
end


