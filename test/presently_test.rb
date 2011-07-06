require File.expand_path('../helper', __FILE__)

class PresentlyTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/twitter/statuses/update.xml" do |env|
      assert_equal 's.presently.com', env[:url].host
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service({'subdomain' => 's',
      'username' => 'u', 'password' => 'p'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Presently, *args
  end
end

