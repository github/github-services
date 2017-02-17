require File.expand_path('../helper', __FILE__)

class PushsaferTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({"private_key" => "a", "device_id" => "a"}, payload)

    def svc.shorten_url(*args)
      "short"
    end

    @stubs.post "/api" do |env|
      assert_equal "pushsafer.com", env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal "a", data["k"]
      assert_equal "a", data["d"]
      [200, {}, '']
    end

    svc.receive_push
  end

  def service(*args)
    super Service::Pushsafer, *args
  end
end

