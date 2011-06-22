require File.expand_path('../helper', __FILE__)

class ServiceTest < Service::TestCase
  class TestService < Service
    def receive_push
    end
  end

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @service = service(:push, 'data', 'payload')
  end

  def test_receive_valid_event
    assert TestService.receive :push, {}, {}

    assert_raise ArgumentError do
      TestService.receive :star, {}, {}
    end
  end

  def test_url_shorten
    url = "http://github.com"
    @stubs.get "/shorten" do |env|
      assert_equal 'api.bit.ly', env[:url].host
      assert_equal 'R_261d14760f4938f0cda9bea984b212e4',
        env[:params]['apiKey']
      assert_equal 'github', env[:params]['login']
      assert_equal url, env[:params]['longUrl']
      [200, {}, {
        'errorCode' => 0,
        'results' => {
          url => {'shortUrl' => 'short'}
        }
      }.to_json]
    end

    assert_equal 'short', @service.shorten_url(url)
  end

  def service(*args)
    super TestService, *args
  end
end
