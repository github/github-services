require File.expand_path('../helper', __FILE__)

class IrkerTest < Service::TestCase
  def setup
    @messages = []
    @server   = lambda do |method, message|
      @messages << [method, message]
    end
  end

  def test_push
    payload = { "repository" => "repository", "commits" => [{ "message" => "commitmsg", "author" => {"name" => "authorname"}, "id" => "8349815fed9", "modified" => ["foo", "bar", "baz"], "added" => [], "removed" => [] }] }
    svc = service({'address' => "localhost", "channels" => "irc://chat.freenode.net/##github-irker", 'project' => 'abc', 'long_url'=>1}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Irker, *args
  end
end



