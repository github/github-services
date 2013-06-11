require File.expand_path('../helper', __FILE__)

class HubcapTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = '/webhook'
    @stubs.post url do |env|
      assert_equal 'hubcap.it', env[:url].host
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      [200, {}, '']
    end

    svc = service(:push, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Hubcap, *args
  end
end
