require File.expand_path('../helper', __FILE__)

class SplendidBaconTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/v1/projects/p/github" do |env|
      assert_equal 'splendidbacon.com', env[:url].host
      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal 1, JSON.parse(data['payload'])['a']
      [200, {}, '']
    end

    svc = service({'token' => 't', 'project_id' => 'p'}, :a => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::SplendidBacon, *args
  end
end

