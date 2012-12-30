require File.expand_path('../helper', __FILE__)

class HipChatTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    payload = {'a' => 1, 'ref' => 'refs/heads/master'}
    @stubs.post "/v1/webhooks/github" do |env|
      form = Rack::Utils.parse_query(env[:body])
      assert_equal payload, JSON.parse(form['payload'])
      assert_equal 'a', form['auth_token']
      assert_equal 'r', form['room_id']
      [200, {}, '']
    end

    svc = service(
      {'auth_token' => 'a', 'room' => 'r'}, payload)
    svc.receive_event
  end

  def service(*args)
    super Service::HipChat, *args
  end
end

