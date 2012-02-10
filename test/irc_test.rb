require File.expand_path('../helper', __FILE__)
require 'stringio'

class IRCTest < Service::TestCase
  class FakeIRC < Service::IRC
    def readable_io
      @readable_io ||= StringIO.new(" 004 n ")
    end

    def writable_io
      @writable_io ||= StringIO.new
    end

    def puts(*args)
      writable_io.puts *args
    end

    def gets
      readable_io.gets
    end

    def eof?
      true
    end

    def shorten_url(*args)
      'short'
    end
  end

  def test_push
    svc = service({'room' => 'r', 'nick' => 'n'}, payload)

    svc.receive_push
    msgs = svc.writable_io.string.split("\n")
    assert_equal "NICK n", msgs.shift
    assert_match "USER n", msgs.shift
    assert_equal "JOIN #r", msgs.shift.strip
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_equal "PART #r", msgs.shift.strip
    assert_equal "QUIT", msgs.shift.strip
    assert_nil msgs.shift
  end

  def test_push_with_nickserv
    svc = service({'room' => 'r', 'nick' => 'n', 'nickservidentify' => 'booya'},
      payload)

    svc.receive_push
    msgs = svc.writable_io.string.split("\n")
    assert_equal "NICK n", msgs.shift
    assert_equal "MSG NICKSERV IDENTIFY booya", msgs.shift
    assert_match "USER n", msgs.shift
    assert_equal "JOIN #r", msgs.shift.strip
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_equal "PART #r", msgs.shift.strip
    assert_equal "QUIT", msgs.shift.strip
    assert_nil msgs.shift
  end

  def test_pull_request
    svc = service(:pull_request, {'room' => 'r', 'nick' => 'n'}, pull_payload)

    svc.receive_pull_request
    msgs = svc.writable_io.string.split("\n")
    assert_equal "NICK n", msgs.shift
    assert_match "USER n", msgs.shift
    assert_equal "JOIN #r", msgs.shift.strip
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_equal "PART #r", msgs.shift.strip
    assert_equal "QUIT", msgs.shift.strip
    assert_nil msgs.shift
  end

  def test_issues
    svc = service(:issues, {'room' => 'r', 'nick' => 'n'}, issues_payload)

    svc.receive_issues
    msgs = svc.writable_io.string.split("\n")
    assert_equal "NICK n", msgs.shift
    assert_match "USER n", msgs.shift
    assert_equal "JOIN #r", msgs.shift.strip
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_equal "PART #r", msgs.shift.strip
    assert_equal "QUIT", msgs.shift.strip
    assert_nil msgs.shift
  end

  def service(*args)
    super FakeIRC, *args
  end
end

