#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/bytestreams'
require 'xmpp4r/semaphore'
include Jabber

class IBBTest < Test::Unit::TestCase
  include ClientTester

  def create_buffer(size)
    ([nil] * size).collect { rand(256).chr }.join
  end

  def test_ibb_target2initiator
    target = Bytestreams::IBBTarget.new(@server, '1', nil, '1@a.com/1')
    initiator = Bytestreams::IBBInitiator.new(@client, '1', nil, '1@a.com/1')

    buffer = create_buffer(9999)

    Thread.new do
      target.accept
      target.write(buffer)
      Thread.pass
      target.close
    end


    initiator.open

    received = ''
    while buf = initiator.read
      received += buf
    end

    initiator.close

    assert_equal(buffer, received)
  end

  def test_ibb_initiator2target
    target = Bytestreams::IBBTarget.new(@server, '1', nil, '1@a.com/1')
    initiator = Bytestreams::IBBInitiator.new(@client, '1', nil, '1@a.com/1')

    buffer = create_buffer(9999)

    Thread.new do
      Thread.pass
      initiator.open
      initiator.write(buffer)
      Thread.pass
      initiator.close
    end


    target.accept

    received = ''
    while buf = target.read
      received += buf
    end

    target.close

    assert_equal(buffer, received)
  end
  
  def test_ibb_pingpong
    ignored_stanzas = 0
    wait = Semaphore.new
    @server.add_message_callback { ignored_stanzas += 1; wait.run }
    @server.add_iq_callback { ignored_stanzas += 1; wait.run }


    target = Bytestreams::IBBTarget.new(@server, '1', nil, '1@a.com/1')
    initiator = Bytestreams::IBBInitiator.new(@client, '1', nil, '1@a.com/1')

    Thread.new do
      target.accept

      while buf = target.read
        target.write(buf)
        target.flush
      end

      target.close
    end


    assert_equal(0, ignored_stanzas)
    @client.send("<iq from='1@a.com/1' type='set'>
                    <close xmlns='http://jabber.org/protocol/ibb' sid='another session id'/>
                  </iq>")
    wait.wait
    assert_equal(1, ignored_stanzas)


    initiator.open


    assert_equal(1, ignored_stanzas)
    @client.send("<message from='1@a.com/1' type='error'>
                    <data xmlns='http://jabber.org/protocol/ibb' sid='another session id' seq='0'/>
                  </message>")
    wait.wait
    assert_equal(2, ignored_stanzas)
    @client.send("<iq from='1@a.com/1' type='set'>
                    <close xmlns='http://jabber.org/protocol/ibb' sid='another session id'/>
                  </iq>")
    wait.wait
    assert_equal(3, ignored_stanzas)


    10.times do
      buf = create_buffer(9999)
      initiator.write(buf)
      initiator.flush

      bufr = ''
      begin
        bufr += initiator.read
      end while bufr.size < buf.size
      assert_equal(buf, bufr)
    end

    initiator.close


    assert_equal(3, ignored_stanzas)
  end

  def test_ibb_error
    target = Bytestreams::IBBTarget.new(@server, '1', nil, '1@a.com/1')
    initiator = Bytestreams::IBBInitiator.new(@client, '1', nil, '1@a.com/1')

    Thread.new do
      target.accept

      @server.send("<message from='1@a.com/1' type='error'>
                      <data xmlns='http://jabber.org/protocol/ibb' sid='#{target.instance_variable_get(:@session_id)}' seq='0'/>
                    </message>")
    end


    initiator.open

    assert_nil(initiator.read)

    initiator.close
  end

  def test_ibb_inactive
    target = Bytestreams::IBBTarget.new(@server, '1', nil, '1@a.com/1')
    initiator = Bytestreams::IBBInitiator.new(@client, '1', nil, '1@a.com/1')

    assert_nil(target.read)
    assert_nil(initiator.read)

    assert_raise(RuntimeError) {
      target.write('a' * target.block_size)
    }
    assert_raise(RuntimeError) {
      initiator.write('a' * initiator.block_size)
    }
  end

  def test_ibb_queueitem
    i1 = Bytestreams::IBBQueueItem.new(:close)
    assert_equal(:close, i1.type)
    assert_nil(i1.seq)

    i2 = Bytestreams::IBBQueueItem.new(:data, 1, Base64::encode64('blah'))
    assert_equal(:data, i2.type)
    assert_equal(1, i2.seq)
    assert_equal('blah', i2.data)

    assert_raise(RuntimeError) {
      i3 = Bytestreams::IBBQueueItem.new(:invalid)
    }
  end
end
