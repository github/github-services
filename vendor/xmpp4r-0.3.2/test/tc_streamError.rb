#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/client'
include Jabber

class ConnectionErrorTest < Test::Unit::TestCase
  @@SOCKET_PORT = 65225

  def setup
    servlisten = TCPServer.new(@@SOCKET_PORT)
    serverwait = Semaphore.new
    @server = nil
    Thread.new do
      Thread.current.abort_on_exception = true
      @server = servlisten.accept
      servlisten.close
      @server.sync = true
      
      serverwait.run
    end

    @conn = TCPSocket::new('localhost', @@SOCKET_PORT)

    serverwait.wait
  end

  def teardown
    @conn.close if not @conn.closed?
    @server.close if not @conn.closed?
  end

  def test_connectionError_start_withexcblock
    @stream = Stream::new
    error = false
    @stream.on_exception do |e, o, w|
      # strange exception, it's caused by REXML, actually
      assert_equal(NameError, e.class)
      assert_equal(Jabber::Stream, o.class)
      assert_equal(:start, w)
      error = true
    end
    assert(!error)
    begin
      # wrong port on purpose
      conn = TCPSocket::new('localhost', 1)
    rescue
    end
    @stream.start(conn)
    sleep 0.2
    assert(error)
    @server.close
    @stream.close
  end

  def test_connectionError_parse_withexcblock
    @stream = Stream::new
    error = false
    @stream.start(@conn)
    @stream.on_exception do |e, o, w|
      assert_equal(REXML::ParseException, e.class)
      assert_equal(Jabber::Stream, o.class)
      assert_equal(:parser, w)
      error = true
    end
    @server.puts('<stream:stream>')
    @server.flush
    assert(!error)
    @server.puts('</blop>')
    @server.flush
    sleep 0.2
    assert(error)
    @server.close
    @stream.close
  end

  def test_connectionError_send_withexcblock
    @stream = Stream::new
    error = 0
    @stream.start(@conn)
    @stream.on_exception do |exc, o, w|
      case w
      when :sending
        assert_equal(IOError, exc.class)
        assert_equal(Jabber::Stream, o.class)
      when :disconnected
        assert_equal(nil, exc)
        assert_equal(Jabber::Stream, o.class)
      else
        assert(false)
      end
      error += 1
    end
    @server.puts('<stream:stream>')
    @server.flush
    assert_equal(0, error)
    @server.close
    sleep 0.1
    assert_equal(1, error)
    @stream.send('</test>')
    sleep 0.1
    @stream.send('</test>')
    sleep 0.1
    assert_equal(3, error)
    @stream.close
  end

  def test_connectionError_send_withoutexcblock
    @stream = Stream::new
    @stream.start(@conn)
    @server.puts('<stream:stream>')
    @server.flush
    assert_raise(Errno::EPIPE) do
      @server.close
     sleep 0.1
      @stream.send('</test>')
      sleep 0.1
      @stream.send('</test>')
      sleep 0.1
    end
  end
end
