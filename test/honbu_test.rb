require File.expand_path('../helper', __FILE__)

class HonbuTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_token = "0123456789abcde"


    data = {
      'token' => test_token,
    }



    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/github" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "integrations.honbu.io"
      assert_equal env[:request_headers]['Authorization'], "#{test_token}"
      assert_equal env[:request_headers]['X-GitHub-Event'], "push"
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
    Service::Honbu
  end
end

