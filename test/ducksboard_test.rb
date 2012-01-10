class DucksboardTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_receive
    # Our service is pretty simple, and so is the test: just check that
    # the original payload is received on our side, where the parsing
    # will happen.
    svc = service({
      'webhook_key' => '1234abcd'
    }, payload)

    @stubs.post '/1234abcd' do |env|
      body = Rack::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv
      [200, {}, '']
    end

    svc.receive
  end

  def test_webhook_key_through_url
    svc = service({
      'webhook_key' => 'https://webhooks.ducksboard.com/abcd1234'
    }, payload)

    @stubs.post '/abcd1234' do |env|
      body = Rack::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv
      [200, {}, '']
    end

    svc.receive
  end

  def test_missing_webhook_key
    svc = service({}, payload)
    assert_raise Service::ConfigurationError do
      svc.receive
    end
  end

  def test_invalid_webhook_key
    svc = service({
      'webhook_key' => 'foobar' # non-hex values
    }, payload)
    assert_raise Service::ConfigurationError do
      svc.receive
    end
  end

  def service(*args)
    super Service::Ducksboard, *args
  end
end
