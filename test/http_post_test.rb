require File.expand_path('../helper', __FILE__)

class HttpPostTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    svc = service(data={
      'url' => 'http://monkey:secret@abc.com/foo/?a=1',
      'secret' => ''
    }, payload)

    @stubs.post "/foo/" do |env|
      assert_equal 'Basic bW9ua2V5OnNlY3JldA==', env[:request_headers]['authorization']
      assert_match /json/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_nil env[:url].port
      params = Faraday::Utils.parse_nested_query(env[:url].query)
      assert_equal({'a' => '1'}, params)

      body = JSON.parse(env[:body])
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      assert_equal payload, body['payload']

      assert_nil env[:request_headers]['X-Hub-Signature']
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_push_with_ssl
    svc = service(data={
      'url' => 'https://abc.com/foo',
      'secret' => ''
    }, payload)

    @stubs.post "/foo/" do |env|
      assert_equal 'abc.com', env[:url].host
      assert_nil env[:url].port
    end
  end

  def test_push_without_scheme
    svc = service({
      'url' => 'abc.com/foo/?a=1',
      'secret' => ''
    }, payload)

    @stubs.post "/foo/" do |env|
      assert_equal 'abc.com', env[:url].host
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_push_as_json
    svc = service({
      'url'          => 'http://monkey:secret@abc.com/foo?a=1',
      'content_type' => 'json'
    }, payload)

    @stubs.post "/foo" do |env|
      assert_equal 'Basic bW9ua2V5OnNlY3JldA==', env[:request_headers]['authorization']
      params = Faraday::Utils.parse_nested_query(env[:url].query)
      assert_equal({'a' => '1'}, params)
      assert_match /json/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_nil env[:request_headers]['X-Hub-Signature']

      body = JSON.parse(env[:body])
      assert_equal payload, body['payload']
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_push_as_json_with_secret
    svc = service({
      'url'          => 'http://abc.com/foo',
      'secret'       => 'monkey',
      'content_type' => 'json'
    }, payload)

    @stubs.post "/foo" do |env|
      assert_nil env[:request_headers]['authorization']
      assert_match /json/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_equal 'sha1='+OpenSSL::HMAC.hexdigest(Service::Web::HMAC_DIGEST,
                                        'monkey', env[:body]),
        env[:request_headers]['X-Hub-Signature']

      body = JSON.parse(env[:body])
      assert_equal payload, body['payload']
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_log_message
    data = {
      'url'          => 'http://abc.com/def',
      'secret'       => 'monkey',
      'content_type' => 'json'
    }

    svc = service(data, payload)
    assert_match /^\[[^\]]+\] 200 #{service_class.hook_name}\/push \{/, svc.log_message(200)
  end

  def service_class
    Service::HttpPost
  end
end

