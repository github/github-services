require File.expand_path('../helper', __FILE__)

class MyGetTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_hook_url = "https://www.myget.org/BuildSource/Hook/feedname?identifier=guid"

    data = {
      'hook_url' => test_hook_url
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "#{test_hook_url}" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "www.myget.org"
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
    Service::MyGet
  end
end

