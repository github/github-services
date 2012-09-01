class SprintlyTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/integration/github/1/push" do |env|
      assert_equal 'my-service.com', env[:url].host
      assert_equal 'application/json',
        env[:request_headers]['content-type']
      assert_equal basic_auth("user", "my_api_key"),
        env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service :push,
      {'email' => 'my_user@foo.bar', 'product_id' => '1', 'api_key' => 'my_api_key'}, payload
    svc.receive_event
  end

  def service(*args)
    super Service::Sprintly, *args
  end
