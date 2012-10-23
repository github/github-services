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
    assert_equal to_irker["to"], "irc://chat.freenode.net/##github-irker"
    assert_match 'abc', to_irker["privmsg"]
    assert_match 'authorname', to_irker["privmsg"]
    assert_match '834981', to_irker["privmsg"]
    assert_match 'commitmsg', to_irker["privmsg"]
  end

  def service(*args)
    super Service::Irker, *args
  end
end



