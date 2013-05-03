require File.expand_path('../helper', __FILE__)

class SimperiumTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_app_id = "sample-app-name"
    test_token = "0123456789abcde"
    test_bucket = "github-event"

    data = {
      'app_id' => test_app_id,
      'token' => test_token,
      'bucket' => test_bucket
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/1/#{test_app_id}/#{test_bucket}/i/#{svc.delivery_guid}" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "api.simperium.com"
      assert_equal env[:request_headers]['Authorization'], "Token #{test_token}"
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Simperium
  end
end

