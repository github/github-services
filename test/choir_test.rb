require File.expand_path('../helper', __FILE__)

class ChoirTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_api_key = "5b975a97c3383a6z"

    data = {
      'api_key' => test_api_key,
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/#{test_api_key}/github" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "hooks.choir.io"
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Choir
  end
end

