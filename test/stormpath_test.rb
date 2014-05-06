require File.expand_path('../helper', __FILE__)

class Hash
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end
end

class StormpathTest < Service::TestCase
  include Service::HttpTestMethods

  TEST_API_KEY_ID = "18WJZYBI2I1YX8LDJBIK5DA6O"
  TEST_API_KEY_SECRET = "5awFkPbNusdIKJkkmjVY6GUjap+VDw39Mnwy16C0luU"

  def data
    {
      'api_key_id' => TEST_API_KEY_ID,
      'api_key_secret' => TEST_API_KEY_SECRET
    }
  end

  def payload
    {
      'commits'=>[{'id'=>'test'}]
    }
  end

  def test_push

    svc = service(data, payload)

    @stubs.post "/vendors/github/events" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:request_headers]['content-type'], "application/json"
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def verify_requires(svc)
    assert_raise Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_requires_api_key_id
    verify_requires(service(data.except!('api_key_id'), payload))
  end

  def test_requires_api_key_secret
    verify_requires(service(data.except!('api_key_secret'), payload))
  end

  def test_invalid_api_key

    invalid_api_key = {'api_key_id' => 'invalid_id', 'api_key_secret' => 'invalid_secret'}
    svc = service(invalid_api_key, payload)

    @stubs.post "/vendors/github/events" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:request_headers]['content-type'], "application/json"
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_match 'guid-', body['guid']
      assert_equal 'push', body['event']
      [401, {}, '']
    end

    verify_requires svc
    @stubs.verify_stubbed_calls
  end

  def test_config

    svc = service(data, payload)

    assert_equal svc.data['api_key_id'], TEST_API_KEY_ID
    assert_equal svc.data['api_key_secret'], TEST_API_KEY_SECRET
  end

  def service_class
    Service::Stormpath
  end
end