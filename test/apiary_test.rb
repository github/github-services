require File.expand_path('../helper', __FILE__)

class ApiaryTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    options = {
      'branch'   => 'master',
      'domain' => 'testvanity',
      'apiary_address'      => nil }
    @svc = service(options, nil)
  end

  def test_push
    @stubs.post "/github/service-hook" do |env|
      body = Faraday::Utils.parse_query(env[:body])
      assert_equal 'api.apiary.io', env[:url].host
      assert_equal @svc.payload, JSON.parse(body['payload'])
      assert_equal @svc.branch, body['branch']
      assert_equal @svc.domain, body['vanity']
      [200, {}, '']
    end
    @svc.receive_event
  end

  def service(*args)
    super Service::Apiary, *args
  end
end
