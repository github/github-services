require 'cgi'

class OnTimeTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.get "/api/version" do |env|
      assert_equal 'www.example.com', env[:url].host
      [200, {}, '{"data":{"major":11,"minor":0,"build":2}}']
    end

    @stubs.post "/api/github" do |env|
      [200, {}, '']
    end

    svc = service({'ontime_url' => 'http://www.example.com/', 'api_key' => 'test_api_key'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::OnTime, *args
  end
end
