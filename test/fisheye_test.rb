require File.expand_path('../helper', __FILE__)

class FishEyeTest < Service::TestCase
  def app
    Service::App
  end

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def data_my_repo
    {
        "url_base" => "http://localhost:6060/foo",
        "token" => "515848d216e3baa46e10d92f21f890f67fea1d12",
        "repository_name" => "myRepo"
    }
  end

  def assert_headers_valid(env)
    assert_equal(data_my_repo["token"], env[:request_headers]["X-Api-Key"])
    assert_equal("application/json", env[:request_headers]["Content-Type"])
  end

  def test_triggers_scanning_custom_repository
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      assert_headers_valid(env)
      [200, {}]
    end

    svc = service :push, data_my_repo, payload
    assert_equal("Ok", svc.receive_push)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_url_with_slash
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      assert_headers_valid(env)
      [200, {}]
    end

    data = data_my_repo
    data['url_base'] = "http://localhost:6060/foo/"

    svc = service :push, data, payload
    assert_equal("Ok", svc.receive_push)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_url_without_http
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      assert_headers_valid(env)
      [200, {}]
    end

    data = data_my_repo
    data['url_base'] = "localhost:6060/foo"

    svc = service :push, data, payload
    assert_equal("Ok", svc.receive_push)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_github_repository
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/grit/scan" do |env|
      [200, {}]
    end

    data = {
      "url_base" => "http://localhost:6060/foo",
      "token" => "515848d216e3baa46e10d92f21f890f67fea1d12",
    }

    svc = service :push, data, payload
    assert_equal("Ok", svc.receive_push)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_empty_custom_repository
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/grit/scan" do |env|
      assert_headers_valid(env)
      [200, {}]
    end

    data = {
      "url_base" => "http://localhost:6060/foo",
      "token" => "515848d216e3baa46e10d92f21f890f67fea1d12",
      "repository_name" => "   "
    }

    svc = service :push, data, payload
    assert_equal("Ok", svc.receive_push)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_url_base
    data = {
      "token" => "515848d216e3baa46e10d92f21f890f67fea1d12"
    }

    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_token
    data = {
      "url_base" => "http://localhost:6060/foo"
    }

    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_data
    svc = service :push, {}, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_data_and_payload
    svc = service :push, {}, {}

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_payload
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      assert_headers_valid(env)
      [200, {}]
    end

    svc = service :push, data_my_repo, {}
    assert_equal("Ok", svc.receive_push)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_error_401
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [401, {}]
    end

    svc = service :push, data_my_repo, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_error_404
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [404, {}]
    end

    svc = service :push, data_my_repo, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_error_other
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [409, {}]
    end

    svc = service :push, data_my_repo, payload

    assert_raise Service::ConfigurationError do
      svc.receive_push
    end

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::FishEye, *args
  end

end


