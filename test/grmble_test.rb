require File.expand_path('../helper', __FILE__)

class GrmbleTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({'room_api_url' => 'http://abc.com/foo'}, payload)

    @stubs.post "/foo/msg" do |env|
      [200, {}, '']
    end

    svc.receive_push
  end

  def service(*args)
    super Service::Grmble, *args
  end
end

