require File.expand_path('../helper', __FILE__)

class PlanioTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.get "/a/sys/fetch_changesets" do |env|
      assert_equal 'r.com', env[:url].host
      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal 'a', env[:params]['key']
      assert_equal 'p', env[:params]['id']
      [200, {}, '']
    end

    svc = service({'address' => 'http://r.com/a/',
      'api_key' => 'a', 'project' => 'p'}, :a => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::Planio, *args
  end
end

