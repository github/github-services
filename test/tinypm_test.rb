require File.expand_path('../helper', __FILE__)

class TinyPMTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @data = {'url' => 'http://tinypm.com/github'}
  end

  def test_push
    @stubs.post "/github" do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_equal 'tinypm.com', env[:url].host
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal JSON.generate(payload), env[:body]
      [200, {}, '']
    end

    svc = service(@data, payload)
    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_no_server
    assert_raises Service::ConfigurationError do
      svc = service :push, {'url' => ''}, payload
      svc.receive_push
    end
  end

  def service(*args)
    super Service::TinyPM, *args
  end
end
