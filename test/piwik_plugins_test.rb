require File.expand_path('../helper', __FILE__)

class PiwikPluginsTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    svc = service({}, 'a' => 1)

    @stubs.post "/postreceive-hook" do |env|
      body = JSON.parse(env[:body])
      assert_equal 'plugins.piwik.org', env[:url].host
      assert_equal 1, body['payload']['a']
      [200, {}, '']
    end

    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::PiwikPlugins
  end
end

