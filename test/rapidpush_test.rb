require File.expand_path('../helper', __FILE__)

class RapidPushTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api" do |env|
      assert_equal 'rapidpush.net', env[:url].host
      data = Rack::Utils.parse_query(env[:body])
      assert_equal 'a', data['apikey']
      [200, {}, '']
    end

    svc = service({'apikey' => 'a'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::RapidPush, *args
  end
end

