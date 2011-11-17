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
      assert_params env[:body], :username => 'admin', :password => 'pwd'
      [200, {}, '<response><auth>TOKEN123</auth></response>']
    end
    @stubs.post "/api/rest/executeBuild.action" do |env|
      assert_params env[:body], :auth => "TOKEN123", :buildKey => "ABC"
      [200, {}, '<response></response>']
    end
    @stubs.post "/api/rest/logout.action" do |env|
      assert_equal "auth=TOKEN123", env[:body]
      [200, {}, '']
    end

    svc = service :push, data, payload
    svc.receive

    @stubs.verify_stubbed_calls
  end

  def test_triggers_compound_build
    @stubs.post "/api/rest/login.action" do |env|
      assert_params env[:body], :username => 'admin', :password => 'pwd'
      [200, {}, '<response><auth>TOKEN123</auth></response>']
    end
    @stubs.post "/api/rest/executeBuild.action" do |env|
      assert_params env[:body], :auth => "TOKEN123", :buildKey => "ABC"
      [200, {}, '<response></response>']
    end
    @stubs.post "/api/rest/executeBuild.action" do |env|
      assert_params env[:body], :auth => "TOKEN123", :buildKey => "A"
      [200, {}, '<response></response>']
    end
    @stubs.post "/api/rest/logout.action" do |env|
      assert_equal "auth=TOKEN123", env[:body]
      [200, {}, '']
    end

    svc = service :push, compound_data1, payload
    svc.receive

    @stubs.verify_stubbed_calls
  end

  def test_triggers_build_with_context_path
    @stubs.post "/context/api/rest/login.action" do |env|
      assert_params env[:body], :username => 'admin', :password => 'pwd'
      [200, {}, '<response><auth>TOKEN123</auth></response>']
    end
    @stubs.post "/context/api/rest/executeBuild.action" do |env|
      assert_params env[:body], :auth => "TOKEN123", :buildKey => "ABC"
      [200, {}, '<response></response>']
    end
    @stubs.post "/context/api/rest/logout.action" do |env|
      assert_equal "auth=TOKEN123", env[:body]
      [200, {}, '']
    end

    data = self.data.update('base_url' => "https://secure.bamboo.com/context")
    svc = service :push, data, payload
    svc.receive

    @stubs.verify_stubbed_calls
  end

  def test_passes_build_error
    @stubs.post "/api/rest/login.action" do |env|
      assert_params env[:body], :username => 'admin', :password => 'pwd'
      [200, {}, '<response><auth>TOKEN123</auth></response>']
    end
    @stubs.post "/api/rest/executeBuild.action" do |env|
      assert_params env[:body], :auth => "TOKEN123", :buildKey => "ABC"
      [200, {}, '<response><error>oh hai</error></response>']
    end
    @stubs.post "/api/rest/logout.action" do |env|
      assert_equal "auth=TOKEN123", env[:body]
      [200, {}, '']
    end

    svc = service :push, data, payload
    assert_raise Service::ConfigurationError do
      svc.receive
    end

    @stubs.verify_stubbed_calls
  end

  def test_requires_valid_login
    @stubs.post "/api/rest/login.action" do
      [401, {}, '']
    end

    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end
  end

  def test_requires_base_url
    data = self.data.update('base_url' => '')
    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end
  end

  def test_requires_build_key
    data = self.data.update('build_key' => '')
    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end
  end

  def test_requires_username
    data = self.data.update('username' => '')
    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end
  end

  def test_requires_password
    data = self.data.update('password' => '')
    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end
  end

  def test_failed_bamboo_server
    svc = service :push, data, payload
    def svc.http_post(*args)
      raise SocketError, "getaddrinfo: Name or service not known"
    end

    assert_raise Service::ConfigurationError do
      svc.receive
    end
  end

  def test_invalid_bamboo_url
    @stubs.post "/api/rest/login.action" do
      [404, {}, '']
    end

    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive
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

  def compound_data1
    {
      "build_key" => "ABC,master:A,rel-1-patches:B,rel-2-patches:C",
      "base_url" => EXAMPLE_BASE_URL,
      "username" => "admin",
      "password" => 'pwd'
    }
  end

  # Assert the value of the params.
  #
  # body     - A String of form-encoded params: "a=1&b=2"
  # expected - A Hash of String keys and values to match against the body.
  #
  # Raises Test::Unit::AssertionFailedError if the assertion doesn't match.
  # Returns nothing.
  def assert_params(body, expected)
    params = Rack::Utils.parse_query(body)
    expected.each do |key, expected_value|
      assert value = params.delete(key.to_s), "#{key} not in #{params.inspect}"
      assert_equal expected_value, value, "#{key} = #{value.inspect}, not #{expected_value.inspect}"
    end

    assert params.empty?, "params has other values: #{params.inspect}"
  end

  def service(*args)
    super Service::Bamboo, *args
  end
end

