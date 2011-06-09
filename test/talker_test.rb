require File.expand_path('../helper', __FILE__)

class TalkerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/room/1" do |env|
      assert_equal 's.talkerapp.com', env[:url].host
      data = Rack::Utils.parse_nested_query(env[:body])
      assert data.key?('message')
      [200, {}, '']
    end

    svc = service({'url' => 'https://s.talkerapp.com/room/1'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Talker, *args
  end
end

