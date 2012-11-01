require File.expand_path('../helper', __FILE__)
require 'cgi'

class OnTimeTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  # This tests the old api paths of OnTime. Where 11.1.0 <= Version < 12.2.0
  def test_push
    @stubs.get "/api/version" do |env|
      assert_equal 'www.example.com', env[:url].host
      [200, {}, '{"data":{"major":12,"minor":0,"build":2}}']
    end

    @stubs.post "/api/github" do |env|
      [200, {}, '']
    end

    svc = service({'ontime_url' => 'http://www.example.com/', 'api_key' => 'test_api_key'}, payload)
    svc.receive_push
  end

  # This tests the new api path for GitHub in OnTime Version 12.2 and later.
  def test_push_v1_api
    @stubs.get "/v122/api/version" do |env|
      assert_equal 'www.example.com', env[:url].host
      [200, {}, '{"data":{"major":12,"minor":2,"build":0}}']
    end

    @stubs.post "/v122/api/v1/github" do |env|
      [200, {}, '']
    end

    svc = service({'ontime_url' => 'http://www.example.com/v122', 'api_key' => 'test_v1_api_key'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::OnTime, *args
  end
end
