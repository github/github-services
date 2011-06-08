require File.expand_path('../helper', __FILE__)

class JacondaTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/v2/rooms/r/notify/github.json" do |env|
      assert_equal 's.jaconda.im', env[:url].host
      assert_match /(^|\&)payload=%7B%22a%22%3A1%7D($|\&)/, env[:body]
      assert_match "digest=d", env[:body]
      [200, {}, '']
    end

    svc = service(
      {'subdomain' => 's', 'room_id' => 'r', 'digest' => 'd'}, 'a' => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::Jaconda, *args
  end
end

