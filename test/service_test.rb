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
  end

  def test_url_shorten
    url = "http://github.com"
    @stubs.post "/" do |env|
      assert_equal 'git.io', env[:url].host
      data = Rack::Utils.parse_query(env[:body])
      assert_equal url, data['url']
      [201, {'Location' => 'short'}, '']
    end

    assert_equal 'short', @service.shorten_url(url)
  end

  def test_ssl_check
    http = @service.http
    def http.post
      raise OpenSSL::SSL::SSLError
    end

    @stubs.post "/" do |env|
      raise "This stub should not be called"
    end

    assert_raises Service::ConfigurationError do
      @service.http_post 'http://abc'
    end
  end

  def service(*args)
    super TestService, *args
  end
end
