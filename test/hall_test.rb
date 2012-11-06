require File.expand_path('../helper', __FILE__)

class HallTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @room_token = "test_token"
  end

  def test_push
    @stubs.post "/api/1/services/github/#{@room_token}" do |env|
      assert_equal 'hall.com', env[:url].host
      [200, {}, '']
    end

    svc = service(
      {'room_token' => 'test_token'}, payload)
    svc.receive_event
  end

  def service(*args)
    super Service::Hall, *args
  end
end
