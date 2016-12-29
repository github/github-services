require File.expand_path('../helper', __FILE__)

class GoCDTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
  end

  def test_push_deleted_branch
    @stubs.post "go/api/material/notify/git" do
      assert false, "service should not be called for deleted branches"
    end

    svc = service :push, data, { "deleted" => true }
    svc.receive
  end

  def test_requires_base_url
    data = self.data.update("base_url" => "")
    svc = service :push, data, payload

    assert_raises Service::ConfigurationError do
      svc.receive
    end
  end

  def test_requires_repository_url
    data = self.data.update("repository_url" => "")
    svc = service :push, data, payload

    assert_raises Service::ConfigurationError do
      svc.receive
    end
  end

  def test_failed_go_server
    svc = service :push, data, payload
    def svc.http_post(*args)
      raise SocketError, "getaddrinfo: Name or service not known"
    end

    assert_raises Service::ConfigurationError do
      svc.receive
    end
  end

  def test_invalid_go_url
    @stubs.post "go/api/material/notify/git" do
      [404, {}, ""]
    end

    svc = service :push, data, payload

    assert_raises Service::ConfigurationError do
      svc.receive
    end
  end

  def test_authorization_passed
    @stubs.post "go/api/material/notify/git" do |env|
      assert_equal basic_auth(:admin, :badger), env[:request_headers]['authorization']
      [200, {}, ""]
    end

    svc = service :push, data, payload

    svc.receive
  end

  def test_triggers_build
    @stubs.post "go/api/material/notify/git" do |env|
      assert_equal "localhost", env[:url].host
      assert_equal 8153, env[:url].port
      [200, {}, ""]
    end

    svc = service :push, data, payload
    svc.receive

    @stubs.verify_stubbed_calls
  end

  def data
    {
      "base_url" => "http://localhost:8153",
      "repository_url" => "git://github.com/gocd/gocd",
      "username" => "admin",
      "password" => "badger"
    }
  end

  def service(*args)
    super Service::GoCD, *args
  end
end

