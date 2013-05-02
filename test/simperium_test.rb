require File.expand_path('../helper', __FILE__)

class SimperiumTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_app_id = "sample-app-name"
    test_token = "0123456789abcde"

    data = {
      'app_id' => test_app_id,
      'token' => test_token
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    @stubs.post "/1/#{test_app_id}/push/i" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "api.simperium.com"
      assert_equal env[:request_headers]['X-Simperium-Token'], test_token
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc = service(data, payload)
    svc.receive_event
  end

  def service_class
    Service::Simperium
  end
end

