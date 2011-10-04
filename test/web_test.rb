require File.expand_path('../helper', __FILE__)

class WebTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({
      'url' => 'http://monkey:secret@abc.com/foo/?a=1',
      'secret' => ''
    }, payload)

    @stubs.post "/foo/" do |env|
      assert_equal 'Basic bW9ua2V5OnNlY3JldA==', env[:request_headers]['authorization']
      assert_match /form/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      params = Rack::Utils.parse_nested_query(env[:url].query)
      assert_equal({'a' => '1'}, params)
      body = Rack::Utils.parse_nested_query(env[:body])
      assert_equal '1', body['a']
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv
      assert_nil env[:request_headers]['X-Hub-Signature']
      assert_equal '1', body['a']
      [200, {}, '']
    end

    svc.receive_push
  end

  def test_push_with_secret
    svc = service({
      'url'    => 'http://abc.com/foo',
      'secret' => 'monkey'
    }, payload)

    @stubs.post "/foo" do |env|
      assert_nil env[:request_headers]['authorization']
      assert_match /form/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_equal 'sha1='+OpenSSL::HMAC.hexdigest(Service::Web::HMAC_DIGEST,
                                        'monkey', env[:body]),
        env[:request_headers]['X-Hub-Signature']
      body = Rack::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv
      [200, {}, '']
    end

    svc.receive_push
  end

  def test_push_as_json
    svc = service({
      'url'          => 'http://monkey:secret@abc.com/foo?a=1',
      'content_type' => 'json'
    }, payload)

    @stubs.post "/foo" do |env|
      assert_equal 'Basic bW9ua2V5OnNlY3JldA==', env[:request_headers]['authorization']
      params = Rack::Utils.parse_nested_query(env[:url].query)
      assert_equal({'a' => '1'}, params)
      assert_match /json/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_nil env[:request_headers]['X-Hub-Signature']
      assert_equal payload, JSON.parse(env[:body])
      [200, {}, '']
    end

    svc.receive_push
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
      assert_equal payload, JSON.parse(env[:body])
      [200, {}, '']
    end

    svc.receive_push
  end

  def service(*args)
    super Service::Web, *args
  end
end

