require File.expand_path('../helper', __FILE__)

class ObsTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def data
    {
      # service works with all current OBS 2.5 instances
      "url" => "http://api.opensuse.org:443",
      "token" => "github/test/token/string",
      # optional
      "project" => "home:adrianSuSE",
      "package" => "4github",
    }
  end

  def test_push
    apicall = "/trigger/runservice"
    @stubs.post apicall do |env|
      assert_equal 'api.opensuse.org', env[:url].host
      params = Faraday::Utils.parse_query env[:body]
      assert_equal 'Token github/test/token/string', env[:request_headers]["Authorization"]
      assert_equal '/trigger/runservice', env[:url].path
      assert_equal 'project=home%3AadrianSuSE&package=4github', env[:url].query
      [200, {}, '']
    end

    svc = service :push, data, payload
    svc.receive
  end

  def service(*args)
    super Service::Obs, *args
  end
end

