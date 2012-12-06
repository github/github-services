require File.expand_path('../helper', __FILE__)
Service::App.set :environment, :test

class FisheyeTest < Service::TestCase
  EXAMPLE_BASE_URL = "http://localhost:6060/foo".freeze

  def app
    Service::App
  end

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_triggers_scanning_custom_repository
    @stubs.post "/foo/rest-service-fecru/admin/repositories-v1/myRepo/scan" do |env|
      [200, {}]
    end

    data = {
      "url_base" => "http://localhost:6060/foo",
      "token" => "515848d216e3baa46e10d92f21f890f67fea1d12",
      "custom_repository_name" => "myRepo"
    }

    svc = service :push, data, payload
    svc.receive

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
    svc.receive

    @stubs.verify_stubbed_calls
  end



  def service(*args)
    super Service::Fisheye, *args
  end


end


