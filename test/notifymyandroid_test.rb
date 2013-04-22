require File.expand_path('../helper', __FILE__)

class NMATest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/publicapi/notify" do |env|
      assert_equal 'www.notifymyandroid.com', env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal 'a', data['apikey']
      [200, {}, '']
    end

    svc = service({'apikey' => 'a'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::NMA, *args
  end
end

