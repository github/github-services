require File.expand_path('../helper', __FILE__)

class ApoioTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/service/github" do |env|
      assert_equal 'api.apo.io', env[:url].host
      assert_equal "test", env[:request_headers]["X-Subdomain"]
      assert_equal "my123token", env[:request_headers]["X-Api-Token"]
      [200, {}, '']
    end

    svc = service(
      {'subdomain' => 'test', 'token' => 'my123token' },
      payload)
    svc.receive_issues
  end

  def service(*args)
    super Service::Apoio, *args
  end
end
