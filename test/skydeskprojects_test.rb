require File.expand_path('../helper', __FILE__)

class SkyDeskProjectsTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/serviceHook"
    data = {
      "project_id" => "1234",
      "token" => "a13d",
    }
    svc = service(data, payload)
    @stubs.post url do |env|
      assert_equal 'projects.skydesk.jp', env[:url].host
      params = Faraday::Utils.parse_query(env[:body])
      assert_equal '1234', params['pId']
      assert_equal 'a13d', params['authtoken']
      assert_equal payload, JSON.parse(params['payload'])
      [200, {}, '']

    end
    svc.receive
  end

  def service(*args)
    super Service::SkyDeskProjects, *args
  end
end
