require File.expand_path('../helper', __FILE__)

class LeanpubTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_api_key = "123abc"
    test_slug = "myamazingbook"

    data = {
      'api_key' => test_api_key,
      'slug' => test_slug
    }

    payload = {}
    svc = service(data, payload)

    @stubs.post "/#{test_slug}/preview?api_key=#{test_api_key}" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "leanpub.com"
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Leanpub
  end
end
