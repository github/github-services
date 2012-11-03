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

    def irc_puts(*args)
      writable_io.puts *args
    end

    def irc_gets
      readable_io.gets
    end

    def irc_eof?
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

  def test_push_with_empty_branch_regex
    svc = service({'room' => 'r', 'nick' => 'n', 'branch_regexes' => ''}, payload)

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

  def test_push_with_single_matching_branch_regex
    svc = service({'room' => 'r', 'nick' => 'n', 'branch_regexes' => 'mast*'}, payload)

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

  def test_push_with_single_mismatching_branch_regex
    svc = service({'room' => 'r', 'nick' => 'n', 'branch_regexes' => '^ticket*'}, payload)

    svc.receive_push
    msgs = svc.writable_io.string.split("\n")
    assert_nil msgs.shift
  end

  def test_push_with_multiple_branch_regexes_where_all_match
    svc = service({'room' => 'r', 'nick' => 'n', 'branch_regexes' => 'mast*,^ticket*'}, payload)

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

  def test_push_with_multiple_branch_regexes_where_one_matches
    svc = service({'room' => 'r', 'nick' => 'n', 'branch_regexes' => 'mast*,^ticket*'}, payload)

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

  def test_push_with_multiple_branch_regexes_where_none_match
    svc = service({'room' => 'r', 'nick' => 'n', 'branch_regexes' => '^feature*,^ticket*'}, payload)

    svc.receive_push
    msgs = svc.writable_io.string.split("\n")
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

  def test_default_port_with_ssl
    svc = service({'ssl' => '1'}, payload)
    assert_equal 9999, svc.port
  end

  def test_default_port_no_ssl
    svc = service({'ssl' => '0'}, payload)
    assert_equal 6667, svc.port
  end
  
  def test_overridden_port
    svc = service({'port' => '1234'}, payload)
    assert_equal 1234, svc.port
  end

  def test_no_colors
    # Default should include color
    svc = service(:pull_request, {'room' => 'r', 'nick' => 'n'}, pull_payload)

    svc.receive_pull_request
    msgs = svc.writable_io.string.split("\n")
    privmsg = msgs[3]  # skip NICK, USER, JOIN
    assert_match /PRIVMSG #r.*grit/, privmsg
    assert_match /\003/, privmsg

    # no_colors should strip color
    svc = service(:pull_request, {'room' => 'r', 'nick' => 'n', 'no_colors' => '1'}, pull_payload)

    svc.receive_pull_request
    msgs = svc.writable_io.string.split("\n")
    privmsg = msgs[3]  # skip NICK, USER, JOIN
    assert_match /PRIVMSG #r.*grit/, privmsg
    assert_no_match /\003/, privmsg
  end

  def service(*args)
    super FakeIRC, *args
  end
end

