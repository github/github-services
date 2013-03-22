require File.expand_path('../helper', __FILE__)

class PushalotTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({"authorization_token" => "be82304d88d74eb884e384a98a282b8a"}, payload)

    def svc.shorten_url(*args)
      "short"
    end

    @stubs.post "/api/sendmessage" do |env|
      assert_equal "pushalot.com", env[:url].host
      data = Rack::Utils.parse_query(env[:body])
      assert_equal "be82304d88d74eb884e384a98a282b8a", data["AuthorizationToken"]
      [200, {}, '']
    end

    svc.receive_push
  end

  def service(*args)
    super Service::Pushalot, *args
  end
end

