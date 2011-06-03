require File.expand_path('../helper', __FILE__)
Service::App.set :environment, :test

class BambooTest < Service::TestCase
  EXAMPLE_BASE_URL = "http://bamboo.example.com".freeze

  def app
    Service::App
  end

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_triggers_build
    @stubs.post "/api/rest/login.action" do |env|
      assert_equal "username=admin&password=pwd", env[:body]
      [200, {}, '<response><auth>TOKEN123</auth></response>']
    end
    @stubs.post "/api/rest/executeBuild.action" do |env|
      assert_equal "auth=TOKEN123&buildKey=ABC", env[:body]
      [200, {}, '<response></response>']
    end
    @stubs.post "/api/rest/logout.action" do |env|
      assert_equal "auth=TOKEN123", env[:body]
      [200, {}, '']
    end

    svc = service :push, data, payload
    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def test_triggers_build_with_context_path
    @stubs.post "/context/api/rest/login.action" do |env|
      assert_equal "username=admin&password=pwd", env[:body]
      [200, {}, '<response><auth>TOKEN123</auth></response>']
    end
    @stubs.post "/context/api/rest/executeBuild.action" do |env|
      assert_equal "auth=TOKEN123&buildKey=ABC", env[:body]
      [200, {}, '<response></response>']
    end
    @stubs.post "/context/api/rest/logout.action" do |env|
      assert_equal "auth=TOKEN123", env[:body]
      [200, {}, '']
    end

    data = self.data.update('base_url' => "https://secure.bamboo.com/context")
    svc = service :push, data, payload
    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def test_passes_build_error
    @stubs.post "/api/rest/login.action" do |env|
      assert_equal "username=admin&password=pwd", env[:body]
      [200, {}, '<response><auth>TOKEN123</auth></response>']
    end
    @stubs.post "/api/rest/executeBuild.action" do |env|
      assert_equal "auth=TOKEN123&buildKey=ABC", env[:body]
      [200, {}, '<response><error>oh hai</error></response>']
    end
    @stubs.post "/api/rest/logout.action" do |env|
      assert_equal "auth=TOKEN123", env[:body]
      [200, {}, '']
    end

    svc = service :push, data, payload
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end

    @stubs.verify_stubbed_calls
  end

  def test_requires_valid_login
    @stubs.post "/api/rest/login.action" do
      [401, {}, '']
    end

    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_requires_base_url
    data = self.data.update('base_url' => '')
    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_requires_build_key
    data = self.data.update('build_key' => '')
    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_requires_username
    data = self.data.update('username' => '')
    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_requires_password
    data = self.data.update('password' => '')
    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_failed_bamboo_server
    svc = service :push, data, payload
    def svc.http_post(*args)
      raise SocketError, "getaddrinfo: Name or service not known"
    end

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_invalid_bamboo_url
    @stubs.post "/api/rest/login.action" do
      [404, {}, '']
    end

    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def data
    {
      "build_key" => "ABC",
      "base_url" => EXAMPLE_BASE_URL,
      "username" => "admin",
      "password" => 'pwd'
    }
  end

  def service(*args)
    super Service::Bamboo, *args
  end
end

