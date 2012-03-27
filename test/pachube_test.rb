require File.expand_path('../helper', __FILE__)

class PachubeTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_require_api_key
    svc = service({}, payload)
    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_require_feed_id
    svc = service({'api_key' => 'abcd1234', 'track_branch' => 'xyz'}, payload)
    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_require_branch
    svc = service({'api_key' => 'abcd1234', 'feed_id' => '123'}, payload)
    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_push
    @stubs.put "/v2/feeds/1234.json" do |env|
      assert_equal 'api.pachube.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      parsed_body = JSON.parse(env[:body])
      assert_equal '1.0.0', parsed_body['version']
      assert_equal [{'current_value' => 3, 'id' => 'grit'}], parsed_body['datastreams']
      [200, {}, '']
    end

    svc = service({'api_key' => 'abcd1234', 'feed_id' => '1234', 'track_branch' => 'xyz'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Pachube, *args
  end
end

