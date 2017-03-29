require File.expand_path('../helper', __FILE__)

class JeapieTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({"token" => "a"}, payload)

    def svc.shorten_url(*args)
      "short"
    end

    @stubs.post "/v2/broadcast/send/message.json" do |env|
      assert_equal "api.jeapie.com", env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal "a", data["token"]
      [200, {}, '']
    end

    svc.receive_event
  end

  def service(*args)
    super Service::Jeapie, *args
  end
end

