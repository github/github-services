#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/bytestreams'
include Jabber

class SOCKS5BytestreamsTest < Test::Unit::TestCase
  include ClientTester

  @@server = Bytestreams::SOCKS5BytestreamsServer.new(65005)
  @@server.add_address('localhost')

  def create_buffer(size)
    ([nil] * size).collect { rand(256).chr }.join
  end

  def test_server2multi
    target1 = Bytestreams::SOCKS5BytestreamsTarget.new(@server, '1', '1@a.com/1', '1@a.com/2')
    target2 = Bytestreams::SOCKS5BytestreamsTarget.new(@server, '2', '2@a.com/1', '2@a.com/2')
    initiator1 = Bytestreams::SOCKS5BytestreamsInitiator.new(@client, '1', '1@a.com/1', '1@a.com/2')
    initiator2 = Bytestreams::SOCKS5BytestreamsInitiator.new(@client, '2', '2@a.com/1', '2@a.com/2')
    initiator1.add_streamhost(@@server)
    initiator2.add_streamhost(@@server)

    buf1 = create_buffer(8192)
    buf2 = create_buffer(8192)

    Thread.new do 
      target1.accept
      target1.write(buf1)
      target1.flush
      target1.close
    end

    Thread.new do
      target2.accept
      target2.write(buf2)
      target2.flush
      target2.close
    end

    initiator1.open
    initiator2.open

    recv1 = ''
    recv2 = ''

    while buf = initiator2.read(256)
      recv2 += buf
    end

    while buf = initiator1.read(256)
      recv1 += buf
    end

    initiator1.close
    initiator2.close

    assert_equal(buf1, recv1)
    assert_equal(buf2, recv2)
  end

  def test_pingpong
    target = Bytestreams::SOCKS5BytestreamsTarget.new(@server, '1', '1@a.com/1', '1@a.com/2')
    initiator = Bytestreams::SOCKS5BytestreamsInitiator.new(@client, '1', '1@a.com/1', '1@a.com/2')
    initiator.add_streamhost(@@server)


    Thread.new do
      target.accept

      while buf = target.read(256)
        target.write(buf)
        target.flush
      end

      target.close
    end


    initiator.open

    10.times do
      buf = create_buffer(8192)
      initiator.write(buf)
      initiator.flush

      bufr = ''
      begin
        bufr += initiator.read(256)
      end while bufr.size < buf.size
      assert_equal(buf, bufr)
    end

    initiator.close
  end
  
end
