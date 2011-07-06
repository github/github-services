require File.expand_path('../helper', __FILE__)

class HipChatTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/v1/webhooks/github" do |env|
      assert_match /(^|\&)payload=%7B%22a%22%3A1%7D($|\&)/, env[:body]
      assert_match "auth_token=a", env[:body]
      assert_match "room_id=r", env[:body]
      [200, {}, '']
    end

    svc = service(
      {'auth_token' => 'a', 'room' => 'r'}, 'a' => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::HipChat, *args
  end
end

