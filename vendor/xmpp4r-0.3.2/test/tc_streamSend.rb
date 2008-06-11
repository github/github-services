#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'tempfile'
require 'io/wait'
require 'xmpp4r'
include Jabber

class StreamSendTest < Test::Unit::TestCase
  def setup
    @tmpfile = Tempfile::new("StreamSendTest")
    @tmpfilepath = @tmpfile.path()
    @tmpfile.unlink
    @servlisten = UNIXServer::new(@tmpfilepath)
    thServer = Thread.new { @server = @servlisten.accept }
    @iostream = UNIXSocket::new(@tmpfilepath)
    @stream = Stream::new
    @stream.start(@iostream)

    thServer.join
  end

  def teardown
    @stream.close
    @server.close
    @servlisten.close
  end

  def mysend(s)
    @stream.send(s)
    @stream.send("\n") #needed for easy test writing
  end
  
  ##
  # Tries to send a basic message
  def test_sendbasic
    mysend(Message::new)
    assert_equal("<message/>\n", @server.gets)
  end

  def test_sendmessage
    mysend(Message::new('lucas@linux.ensimag.fr', 'coucou'))
    assert_equal("<message to='lucas@linux.ensimag.fr'><body>coucou</body></message>\n", @server.gets)
  end

  def test_sendpresence
    mysend(Presence::new)
    assert_equal("<presence/>\n", @server.gets)
  end

  def test_sendiq
    mysend(Iq::new)
    assert_equal("<iq/>\n", @server.gets)
  end

end
