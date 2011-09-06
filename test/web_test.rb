require File.expand_path('../helper', __FILE__)

class WebTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({
      'url' => 'http://abc.com/foo',
      'secret' => ''
    }, payload)

    @stubs.post "/foo" do |env|
      assert_match /form/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      body = Rack::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv
      assert_nil env[:request_headers]['X-Hub-Signature']
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
      assert_match /form/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_equal OpenSSL::HMAC.hexdigest(Service::Web::HMAC_DIGEST,
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
      'url'          => 'http://abc.com/foo',
      'content_type' => 'json'
    }, payload)

    @stubs.post "/foo" do |env|
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
      assert_match /json/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_equal OpenSSL::HMAC.hexdigest(Service::Web::HMAC_DIGEST,
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

