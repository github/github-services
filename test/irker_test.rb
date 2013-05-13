require File.expand_path('../helper', __FILE__)
require 'json'

class IrkerTest < Service::TestCase
  class FakeIrkerd
    def initialize
      @messages = []
    end
    def puts(message)
      @messages << message
    end
    def messages
      @messages
    end
  end
  def setup
    @server = FakeIrkerd.new
  end

  def test_push
    payload = { "repository" => "repository", "commits" => [{ "message" => "commitmsg", "author" => {"name" => "authorname"}, "id" => "8349815fed9", "modified" => ["foo", "bar", "baz"], "added" => [], "removed" => [] }] }
    svc = service({'address' => "localhost", "channels" => "irc://chat.freenode.net/##github-irker", 'project' => 'abc', 'long_url'=>1}, payload)
    svc.irker_con = @server
    svc.receive_push

    assert msg = @server.messages.shift
    to_irker = JSON.parse(msg)
    target = to_irker["to"]
    if target.kind_of?(Array) then
      assert_equal target.size, 1
      target = target[0]
    end
    assert_equal target, "irc://chat.freenode.net/##github-irker"
    assert_match 'abc', to_irker["privmsg"]
    assert_match 'authorname', to_irker["privmsg"]
    assert_match '834981', to_irker["privmsg"]
    assert_match 'commitmsg', to_irker["privmsg"]
  end

  def test_channels
    payload = { "repository" => "repository", "commits" => [{ "message" => "commitmsg", "author" => {"name" => "authorname"}, "id" => "8349815fed9", "modified" => ["foo", "bar", "baz"], "added" => [], "removed" => [] }] }
    svc = service({'address' => "localhost", "channels" => "irc://chat.freenode.net/#commits;irc://chat.freenode.net/#irker;irc://chat.freenode.net/testuser,isnick", 'project' => 'abc', 'long_url' => 1}, payload)
    svc.irker_con = @server
    svc.receive_push

    assert msg = @server.messages.shift
    to_irker = JSON.parse(msg)
    assert_equal to_irker["to"].sort, ["irc://chat.freenode.net/#commits", "irc://chat.freenode.net/#irker", "irc://chat.freenode.net/testuser,isnick"].sort
  end

  def test_multiline
    payload = { "repository" => "repository", "commits" => [{ "message" => "very\nlong\nmessage", "author" => {"name" => "authorname"}, "id" => "8349815fed9", "modified" => ["foo", "bar", "baz"], "added" => [], "removed" => [] }] }
    svc_short = service({'address' => "localhost", "channels" => "irc://chat.freenode.net/##github-irker", 'project' => 'abc', 'long_url'=>1, 'full_commits'=>0}, payload)
    svc_long = service({'address' => "localhost", "channels" => "irc://chat.freenode.net/##github-irker", 'project' => 'abc', 'long_url'=>1, 'full_commits'=>1}, payload)
    svc_long.irker_con = svc_short.irker_con = @server

    svc_short.receive_push
    assert_equal @server.messages.size, 1
    @server.messages.shift
    assert_equal @server.messages.size, 0

    svc_long.receive_push
    assert_equal @server.messages.size, 1
    assert msg = @server.messages.shift
    to_irker = JSON.parse(msg)
    assert_equal to_irker["privmsg"].scan("\n").size, 3
  end

  def test_duplicates
    payload = { "repository" => "repository", "commits" => [{ "message" => "msg", "author" => {"name" => "authorname"}, "id" => "3ef829ad", "modified" => ["foo", "bar"], "added" => ["foo"], "removed" => ["bar"] }] }
    svc = service({'address' => "localhost", "channels" => "irc://chat.freenode.net/#commits", 'project' => 'abc', 'long_url' => 1}, payload)
    svc.irker_con = @server
    svc.receive_push

    assert msg = @server.messages.shift
    to_irker = JSON.parse(msg)
    assert_equal to_irker["privmsg"].scan("foo").size, 1
    assert_equal to_irker["privmsg"].scan("bar").size, 1
  end

  def test_file_consolidation
    payload = { "repository" => "repository", "commits" => [{ "message" => "commitmsg", "author" => {"name" => "authorname"}, "id" => "8349815fed9", "modified" => ["foo/a/bar/baz/andsomemore/filenumberone.hpp", "foo/a/bar/baz/andsomemore/filenumbertwo.hpp", "foo/b/quuuuuuuuuuuux/filenumberthree.cpp", "foo/b/quuuuuuuuuuuux/filenumberfour.cpp", "foo/b/bar/baz/andsomemore/filenumberfive.cpp", "foo/b/bar/baz/andsomemore/filenumbersix.cpp", "foo/b/filenumberseven.cpp"], "added" => [], "removed" => [] }] }
    svc = service({'address' => "localhost", "channels" => "irc://chat.freenode.net/#commits;irc://chat.freenode.net/#irker;irc://chat.freenode.net/testuser,isnick", 'project' => 'abc', 'long_url' => 1}, payload)
    svc.irker_con = @server
    svc.receive_push

    assert msg = @server.messages.shift
  end

  def service(*args)
    super Service::Irker, *args
  end
end



