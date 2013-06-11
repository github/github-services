require File.expand_path('../helper', __FILE__)

class TddiumTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_token = "0123456789abcde"

    data = {
      'token' => test_token,
      'override_url' => ""
    }

    svc = service(data, push_payload)

    @stubs.post "/1/github/#{test_token}" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "hooks.tddium.com"
      assert_equal 'refs/heads/master', body['payload']['ref']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_pull_request
    test_token = "0123456789abcde"

    data = {
      'token' => test_token,
    }

    svc = service(:pull_request, data)

    @stubs.post "/1/github/#{test_token}" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "hooks.tddium.com"
      assert_equal 'pull_request', body['event']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_override_url
    test_token = "0123456789abcde"
    test_url = "https://some.other.com/prefix"

    data = {
      'token' => test_token,
      'override_url' => test_url
    }

    svc = service(data, push_payload)

    @stubs.post "/prefix/#{test_token}" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "some.other.com"
      assert_equal 'refs/heads/master', body['payload']['ref']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Tddium
  end
end

