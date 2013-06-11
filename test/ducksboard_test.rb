class DucksboardTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def receive_helper(event)
    # Our service is pretty simple, and so is the test: just check that
    # the original payload and event are received on our side,
    # where the parsing will happen.
    svc = service(event, {'webhook_key' => '1234abcd'}, payload)

    @stubs.post '/1234abcd' do |env|
      body = Faraday::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['content'])
      assert_equal recv['payload'], payload
      assert_equal recv['event'], event.to_s
      [200, {}, '']
    end

    event_method = "receive_#{event}"
    svc.send(event_method)
  end

  def test_receive
    [:push, :issues, :fork, :watch].each do |event|
      receive_helper event
    end
  end

  def test_webhook_key_through_url
    svc = service({
      'webhook_key' => 'https://webhooks.ducksboard.com/abcd1234'
    }, payload)

    @stubs.post '/abcd1234' do |env|
      body = Faraday::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['content'])
      assert_equal recv['payload'], payload
      [200, {}, '']
    end

    svc.receive
  end

  def test_many_webhook_keys
    svc = service({
      'webhook_key' => '1 2 https://webhooks.ducksboard.com/3 ' \
                       'https://webhooks.ducksboard.com/4 5 6'
    }, payload)

    posted = []

    (1..6).each do |endpoint|
      @stubs.post "/#{endpoint}" do |env|
        posted << endpoint
        body = Faraday::Utils.parse_nested_query(env[:body])
        recv = JSON.parse(body['content'])
        assert_equal recv['payload'], payload
        [200, {}, '']
      end
    end

    svc.receive

    # check that only the 5 first keys are used
    assert_equal posted, [1, 2, 3, 4, 5]
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

  def test_invalid_key_of_many
    svc = service({
      'webhook_key' => 'abc123 foobar' # non-hex values
    }, payload)
    assert_raise Service::ConfigurationError do
      svc.receive
    end
  end

  def service(*args)
    super Service::Ducksboard, *args
  end
end
