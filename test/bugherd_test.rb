class BugherdTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/github_web_hook/KEY" do |env|
      assert_equal 'www.bugherd.com', env[:url].host
      assert_equal 'application/json',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push,
      {'url' => '', 'project_key' => 'KEY'}, payload
    svc.receive_push
  end

  def service(*args)
    super Service::Bugherd, *args
  end
end
