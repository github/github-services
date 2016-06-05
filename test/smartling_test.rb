require File.expand_path('../helper', __FILE__)

class SmartlingTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_requires_service_url
    data = self.data.update("service_url" => "")
    svc = service :push, data, payload

    assert_raises Service::ConfigurationError do
      svc.receive
    end
  end

  def test_requires_project_id
    data = self.data.update("project_id" => "")
    svc = service :push, data, payload

    assert_raises Service::ConfigurationError do
      svc.receive
    end
  end

  def test_requires_api_key
    data = self.data.update("api_key" => "")
    svc = service :push, data, payload

    assert_raises Service::ConfigurationError do
      svc.receive
    end
  end

  def test_requires_config_path
    data = self.data.update("config_path" => "")
    svc = service :push, data, payload

    assert_raises Service::ConfigurationError do
      svc.receive
    end
  end

  def test_requires_master_only_no_master
    @stubs.post "/github" do |env|
      assert_equal "capi.smatling.com", env[:url].host
      [200, {}, '']
    end
    svc = service :push, data, payload
    svc.receive
    @stubs.verify_stubbed_calls
  end

  def test_requires_master_only_no_branch
    payload = self.payload.update("ref" => "refs/heads/branch_name")
    @stubs.post "/github" do |env|
      assert_equal "capi.smatling.com", env[:url].host
      [200, {}, '']
    end
    svc = service :push, data, payload
    svc.receive
    @stubs.verify_stubbed_calls
  end

  def test_requires_master_only_nil_master
    data = self.data.update("master_only" => nil)
    @stubs.post "/github" do |env|
      assert_equal "capi.smatling.com", env[:url].host
      [200, {}, '']
    end
    svc = service :push, data, payload
    svc.receive
    @stubs.verify_stubbed_calls
  end

  def test_requires_master_only_nil_branch
    data = self.data.update("master_only" => nil)
    payload = self.payload.update("ref" => "refs/heads/branch_name")
    @stubs.post "/github" do |env|
      assert_equal "capi.smatling.com", env[:url].host
      [200, {}, '']
    end
    svc = service :push, data, payload
    svc.receive
    @stubs.verify_stubbed_calls
  end

  def test_requires_master_only_yes_master
    data = self.data.update("master_only" => "1")
    @stubs.post "/github" do |env|
      assert_equal "capi.smatling.com", env[:url].host
      [200, {}, '']
    end
    svc = service :push, data, payload
    svc.receive
    @stubs.verify_stubbed_calls
  end

  def test_requires_master_only_yes_branch
    payload = self.payload.update("ref" => "refs/heads/branch_name")
    data = self.data.update("master_only" => "1")
    @stubs.post "/github" do |env|
      assert_equal "capi.smatling.com", env[:url].host
      [200, {}, '']
    end
    svc = service :push, data, payload
    svc.receive
    begin
      @stubs.verify_stubbed_calls
    rescue RuntimeError
    else
      assert_true false
    end
  end

  def test_error
    @stubs.post "/github" do |env|
      assert_equal "capi.smatling.com", env[:url].host
      [401, {}, '']
    end
    svc = service :push, data, payload
    begin
      svc.receive
    rescue Service::ConfigurationError
    else
      assert_true false
    end
    @stubs.verify_stubbed_calls
  end

  def test_ok
    @stubs.post "/github" do |env|
      assert_equal "capi.smatling.com", env[:url].host
      body = JSON.parse(env[:body])
      assert_equal data["project_id"], body.delete("projectId")
      assert_equal data["api_key"], body.delete("apiKey")
      assert_equal data["config_path"], body.delete("resourceFile")
      assert_equal payload, body
      [200, {}, '']
    end
    svc = service :push, data, payload
    svc.receive
    @stubs.verify_stubbed_calls
  end

  def data
    {
      "service_url" => "http://capi.smatling.com",
      "project_id" => "d86077368",
      "api_key" => "2c1ad0bb-e9b6-4c20-b536-1006502644a2",
      "config_path" => "smartling-config.json",
      "master_only" => "0"
    }
  end

  def service(*args)
    super Service::Smartling, *args
  end
end
