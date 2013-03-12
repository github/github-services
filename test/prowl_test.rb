require File.expand_path('../helper', __FILE__)

class ProwlTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/publicapi/add" do |env|
      assert_equal 'api.prowlapp.com', env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal 'a', data['apikey']
      [200, {}, '']
    end

    svc = service({'apikey' => 'a'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Prowl, *args
  end
end

