require File.expand_path('../helper', __FILE__)

class NamecastTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    data = {}

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/hooks/dnssync.php" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "www.namecast.net"
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Namecast
  end
end
