require File.expand_path('../helper', __FILE__)

class GroveTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @channel_token = "test_token"
  end

  def test_push
    @stubs.post "/api/services/github/#{@channel_token}" do |env|
      assert_equal 'grove.io', env[:url].host
      [200, {}, '']
    end

    svc = service(
      {'channel_token' => 'test_token'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Grove, *args
  end
end

