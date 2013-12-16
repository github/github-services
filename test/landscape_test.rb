require File.expand_path('../helper', __FILE__)

class LandscapeTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    data = {}
    payload = {
        'commits'=>[{'id'=>'test'}],
        'repository'=>{'id'=>'repoid'}
    }

    svc = service(data, payload)

    @stubs.post "/hooks/github" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "landscape.io"
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      assert_equal 'repoid', body['payload']['repository']['id']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end
  def service_class
    Service::Landscape
  end
end

