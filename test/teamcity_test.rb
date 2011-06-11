require File.expand_path('../helper', __FILE__)

class TeamCityTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/abc/httpAuth/action.html"
    @stubs.get url do |env|
      assert_equal 'teamcity.com', env[:url].host
      assert_equal 'btid', env[:params]['add2Queue']
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service({
      'base_url' => 'http://teamcity.com/abc',
      'build_type_id' => 'btid',
      'username' => 'u',
      'password' => 'p'
    }, 'payload')
    svc.receive_push
  end

  def service(*args)
    super Service::TeamCity, *args
  end
end

