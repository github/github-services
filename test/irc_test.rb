require File.expand_path('../helper', __FILE__)
require 'stringio'

class IRCTest < Service::TestCase
  class FakeIRC < Service::IRC
    def readable_irc
      nick = data['nick']
      @readable_irc ||= StringIO.new(" 004 #{nick} \r\n:NickServ!nickserv@network.net PRIVMSG #{nick} :Successfully authenticated as #{nick}.\r\n")
    end

    def writable_irc
      @writable_irc ||= StringIO.new
    end

    def irc_eof?
      true
    end

    def shorten_url(*args)
      'short'
    end
  end

  def test_push
    expected = [
      "NICK n",
      "USER n",
      "JOIN #r",
      /PRIVMSG #r.*grit/,
      /PRIVMSG #r.*grit/,
      /PRIVMSG #r.*grit/,
      /PRIVMSG #r.*grit/,
      "PART #r",
      "QUIT"
    ]

    svc = service({'room' => 'r', 'nick' => 'n'}, payload)

    svc.receive_push
    assert_irc_commands expected, svc.writable_irc.string
    assert_equal 1, svc.remote_calls.size

    svc.remote_calls.each do |text|
      incoming, outgoing = split_irc_debug(text)
      modified = expected.dup
      modified.unshift 'IRC Log:'

      assert_irc_commands ['004 n'], incoming
      assert_irc_commands modified, outgoing
    end
  end

  def test_push_with_password
    expected = [
      "PASS pass",
      "NICK n",
      "USER n",
      "JOIN #r",
      /PRIVMSG #r.*grit/,
      /PRIVMSG #r.*grit/,
      /PRIVMSG #r.*grit/,
      /PRIVMSG #r.*grit/,
      "PART #r",
      "QUIT"
    ]

    svc = service({'room' => 'r', 'nick' => 'n', 'password' => 'pass'}, payload)

    svc.receive_push
    assert_irc_commands expected, svc.writable_irc.string
    assert_equal 1, svc.remote_calls.size

    svc.remote_calls.each do |text|
      incoming, outgoing = split_irc_debug(text)
      censored = expected.dup
      censored[0] = 'PASS ****'
      censored.unshift 'IRC Log:'

      assert_irc_commands ['004 n'], incoming
      assert_irc_commands censored, outgoing
    end
  end

  def test_push_with_nickserv
    expected = [
      "NICK n",
      "USER n",
      "PRIVMSG NICKSERV :IDENTIFY pass",
      "JOIN #r",
      /PRIVMSG #r.*grit/,
      /PRIVMSG #r.*grit/,
      /PRIVMSG #r.*grit/,
      /PRIVMSG #r.*grit/,
      "PART #r",
      "QUIT"
    ]
    expected_incoming = [
      '004 n',
      ':NickServ!nickserv@network.net PRIVMSG n :Successfully authenticated as n.'
    ]

    svc = service({'room' => 'r', 'nick' => 'n', 'nickserv_password' => 'pass'}, payload)

    svc.receive_push
    assert_irc_commands expected, svc.writable_irc.string
    assert_equal 1, svc.remote_calls.size

    svc.remote_calls.each do |text|
      incoming, outgoing = split_irc_debug(text)
      censored = expected.dup
      censored[2] = "PRIVMSG NICKSERV :IDENTIFY ****"
      censored.unshift 'IRC Log:'

      assert_irc_commands expected_incoming, incoming
      assert_irc_commands censored, outgoing
    end
  end

  def test_push_with_empty_branch_regex
    svc = service({'room' => 'r', 'nick' => 'n', 'branch_regexes' => ''}, payload)

    svc.receive_push
    msgs = svc.writable_irc.string.split("\n")
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
    msgs = svc.writable_irc.string.split("\n")
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
    msgs = svc.writable_irc.string.split("\n")
    assert_nil msgs.shift
  end

  def test_push_with_multiple_branch_regexes_where_all_match
    svc = service({'room' => 'r', 'nick' => 'n', 'branch_regexes' => 'mast*,^ticket*'}, payload)

    svc.receive_push
    msgs = svc.writable_irc.string.split("\n")
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
    msgs = svc.writable_irc.string.split("\n")
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
    msgs = svc.writable_irc.string.split("\n")
    assert_nil msgs.shift
  end

  def test_commit_comment
    svc = service(:commit_comment, {'room' => 'r', 'nick' => 'n'}, commit_comment_payload)

    svc.receive_commit_comment
    msgs = svc.writable_irc.string.split("\n")
    assert_equal "NICK n", msgs.shift
    assert_match "USER n", msgs.shift
    assert_equal "JOIN #r", msgs.shift.strip
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_equal "PART #r", msgs.shift.strip
    assert_equal "QUIT", msgs.shift.strip
    assert_nil msgs.shift
  end

  def test_pull_request
    svc = service(:pull_request, {'room' => 'r', 'nick' => 'n'}, pull_payload)

    svc.receive_pull_request
    msgs = svc.writable_irc.string.split("\n")
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
    msgs = svc.writable_irc.string.split("\n")
    assert_equal "NICK n", msgs.shift
    assert_match "USER n", msgs.shift
    assert_equal "JOIN #r", msgs.shift.strip
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_equal "PART #r", msgs.shift.strip
    assert_equal "QUIT", msgs.shift.strip
    assert_nil msgs.shift
  end

  def test_issue_comment
    svc = service(:issue_comment, {'room' => 'r', 'nick' => 'n'}, issue_comment_payload)

    svc.receive_issue_comment
    msgs = svc.writable_irc.string.split("\n")
    assert_equal "NICK n", msgs.shift
    assert_match "USER n", msgs.shift
    assert_equal "JOIN #r", msgs.shift.strip
    assert_match /PRIVMSG #r.*grit/, msgs.shift
    assert_equal "PART #r", msgs.shift.strip
    assert_equal "QUIT", msgs.shift.strip
    assert_nil msgs.shift
  end

  def test_pull_request_review_comment
    svc = service(:pull_request_review_comment, {'room' => 'r', 'nick' => 'n'}, pull_request_review_comment_payload)

    svc.receive_pull_request_review_comment
    msgs = svc.writable_irc.string.split("\n")
    assert_equal "NICK n", msgs.shift
    assert_match "USER n", msgs.shift
    assert_equal "JOIN #r", msgs.shift.strip
    assert_match /PRIVMSG #r.*grit.*pull request #5 /, msgs.shift
    assert_equal "PART #r", msgs.shift.strip
    assert_equal "QUIT", msgs.shift.strip
    assert_nil msgs.shift
  end

  def test_default_port_with_ssl
    svc = service({'ssl' => '1'}, payload)
    assert_equal 6697, svc.port
  end

  def test_default_port_no_ssl
    svc = service({'ssl' => '0'}, payload)
    assert_equal 6667, svc.port
  end

  def test_default_port_with_empty_string
    svc = service({'port' => ''}, payload)
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
    msgs = svc.writable_irc.string.split("\n")
    privmsg = msgs[3]  # skip NICK, USER, JOIN
    assert_match /PRIVMSG #r.*grit/, privmsg
    assert_match /\003/, privmsg

    # no_colors should strip color
    svc = service(:pull_request, {'room' => 'r', 'nick' => 'n', 'no_colors' => '1'}, pull_payload)

    svc.receive_pull_request
    msgs = svc.writable_irc.string.split("\n")
    privmsg = msgs[3]  # skip NICK, USER, JOIN
    assert_match /PRIVMSG #r.*grit/, privmsg
    assert_no_match /\003/, privmsg
  end

  def service(*args)
    super FakeIRC, *args
  end

  def assert_irc_commands(expected, text)
    lines = text.split("\n")
    expected.each do |line|
      assert_match line, lines.shift
    end
    assert_nil lines.shift
  end

  def split_irc_debug(text)
    all_lines = text.split("\n")
    incoming, outgoing = all_lines.partition { |l| l =~ /^\=/ }
    incoming.each { |s| s.sub!(/^\=\> /, '') }
    outgoing.each { |s| s.sub!(/^\>\> /, '') }
    [incoming.join("\n"), outgoing.join("\n")]
  end
end
