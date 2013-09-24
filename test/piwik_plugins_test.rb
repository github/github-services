require File.expand_path('../helper', __FILE__)

class PiwikPluginsTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service :push, {}, 'a' => 1

    @stubs.post "/postreceive-hook" do |env|
      assert_equal 'plugins.piwik.org', env[:url].host
      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal 1, JSON.parse(data['payload'])['a']
      [200, {}, '']
    end

    svc.receive

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::PiwikPlugins, *args
  end
end

