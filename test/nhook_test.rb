require File.expand_path('../helper', __FILE__)

class NHookTest < Service::TestCase
    include Service::HttpTestMethods

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    test_apiKey = '143021'
    data = {'api_key' => test_apiKey}

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/github/#{test_apiKey}" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, 'api.nhook.net'
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::NHook
  end
end