class LogglyTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/inputs/input-foo" do |env|
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal 'logs.loggly.com', env[:url].host
      [200, {}, '']
    end

    svc = service(
      {"input_token" => "input-foo"},
      payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Loggly, *args
  end
end
