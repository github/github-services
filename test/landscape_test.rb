require File.expand_path('../helper', __FILE__)

class LandscapeTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_token = "dcf27a5e4a964ea9b7623f5f5dc56252"

    data = {
      'token' => test_token,
    }

    payload = {
        'commits'=>[{'id'=>'test'}],
        'repository'=>{'id'=>'repoid'}
    }
    svc = service(data, payload)

    @stubs.post "/hooks/github" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "landscape.io"
      assert_equal env[:request_headers]['Authorization'], "Token #{test_token}"
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

  def test_set_hook_url
    test_token = "dcf27a5e4a964ea9b7623f5f5dc56252"

    data = {
      'token' => test_token,
      'hook_url' => 'https://test.landscape.io/hooks/github'
    }

    payload = {}
    svc = service(data, payload)

    @stubs.post "/hooks/github" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "test.landscape.io"
      assert_equal env[:request_headers]['Authorization'], "Token #{test_token}"
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Landscape
  end
end

