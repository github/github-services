require File.expand_path('../helper', __FILE__)
Service::App.set :environment, :test

class FishEyeTest < Service::TestCase

  def app
    Service::App
  end

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def data_my_repo
    {
        "FishEye_Base_URL" => "http://localhost:6060/foo",
        "REST_API_Token" => "515848d216e3baa46e10d92f21f890f67fea1d12",
        "FishEye_Repository_Name" => "myRepo"
    }
  end

  def test_triggers_scanning_custom_repository
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [200, {}]
    end

    svc = service :push, data_my_repo, payload
    assert_equal("Ok", svc.receive)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_url_with_slash
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [200, {}]
    end

    data = data_my_repo
    data['FishEye_Base_URL'] = "http://localhost:6060/foo/"

    svc = service :push, data, payload
    assert_equal("Ok", svc.receive)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_url_without_http
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [200, {}]
    end

    data = data_my_repo
    data['FishEye_Base_URL'] = "localhost:6060/foo"

    svc = service :push, data, payload
    assert_equal("Ok", svc.receive)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_github_repository
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/grit/scan" do |env|
      [200, {}]
    end

    data = {
      "FishEye_Base_URL" => "http://localhost:6060/foo",
      "REST_API_Token" => "515848d216e3baa46e10d92f21f890f67fea1d12",
    }

    svc = service :push, data, payload
    assert_equal("Ok", svc.receive)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_empty_custom_repository
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/grit/scan" do |env|
      [200, {}]
    end

    data = {
      "FishEye_Base_URL" => "http://localhost:6060/foo",
      "REST_API_Token" => "515848d216e3baa46e10d92f21f890f67fea1d12",
      "FishEye_Repository_Name" => "   "
    }

    svc = service :push, data, payload
    assert_equal("Ok", svc.receive)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_FishEye_Base_URL
    data = {
      "REST_API_Token" => "515848d216e3baa46e10d92f21f890f67fea1d12"
    }

    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_token
    data = {
      "FishEye_Base_URL" => "http://localhost:6060/foo"
    }

    svc = service :push, data, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_data
    svc = service :push, {}, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_data_and_payload
    svc = service :push, {}, {}

    assert_raise Service::ConfigurationError do
      svc.receive
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_missing_payload
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [200, {}]
    end

    svc = service :push, data_my_repo, {}
    assert_equal("Ok", svc.receive)

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_error_401
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [401, {}]
    end

    svc = service :push, data_my_repo, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_error_404
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [404, {}]
    end

    svc = service :push, data_my_repo, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end

    @stubs.verify_stubbed_calls
  end

  def test_triggers_scanning_error_other
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [409, {}]
    end

    svc = service :push, data_my_repo, payload

    assert_raise Service::ConfigurationError do
      svc.receive
    end

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::FishEye, *args
  end

end


