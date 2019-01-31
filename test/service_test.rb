# encoding: utf-8

require File.expand_path('../helper', __FILE__)

class ServiceTest < Service::TestCase
  class TestService < Service
    def receive_push
    end
  end

  class TestCatchAllService < Service
    def receive_event
    end
  end

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @service = service(:push, 'data', 'payload')
  end

  def test_receive_valid_event
    assert TestService.receive :push, {}, {}
  end

  def test_specific_event_method
    assert_equal 'receive_push', TestService.new(:push, {}, {}).event_method
  end

  def test_catch_all_event_method
    assert_equal 'receive_event', TestCatchAllService.new(:push, {}, {}).event_method
  end

  def test_missing_method
    assert_equal nil, TestService.new(:issues, {}, {}).event_method
  end

  def test_http_callback
    @stubs.post '/' do |env|
      [200, {'x-test' => 'booya'}, 'ok']
    end

    @service.http.post '/'

    @service.http_calls.each do |env|
      assert_equal '/', env[:request][:url]
      assert_equal '0', env[:request][:headers]['Content-Length']
      assert_equal 200, env[:response][:status]
      assert_equal 'booya', env[:response][:headers]['x-test']
      assert_equal 'ok', env[:response][:body]
    end

    assert_equal 1, @service.http_calls.size
  end

  def test_url_shorten
    url = "http://github.com"
    @stubs.post "/" do |env|
      assert_equal 'git.io', env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
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

  def test_http_only_with_prefix
    ["ftp://1.1.1.1", "file:///etc/passwd"].each do |url|
      http = @service.http
      http.url_prefix = URI::parse(url)

      assert_raises Service::ConfigurationError do
        @service.http_post "/this/is/a/url"
      end
      assert_raises Service::ConfigurationError do
        @service.http_get "/this/is/a/url"
      end
    end
  end

  def test_http_only_with_full_url
    ["ftp://1.1.1.1", "file:///etc/passwd"].each do |url|
      http = @service.http

      assert_raises Service::ConfigurationError do
        @service.http_post url
      end
      assert_raises Service::ConfigurationError do
        @service.http_get url
      end
    end
  end

  def test_http_only_with_prefix_and_fqdn
    ["ftp://1.1.1.1", "file:///etc/passwd"].each do |url|
      http = @service.http
      http.url_prefix = URI::parse(url)

      assert_raises Service::ConfigurationError do
        @service.http_post "ftp:///this/is/a/url"
      end
      assert_raises Service::ConfigurationError do
        @service.http_get "ftp:///this/is/a/url"
      end
    end
  end

  def test_http_get_url_strip
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get("/") { |env| [200, {}, "ok"] }
    stubs.get("/   ") { |env| [200, {}, "nope"] }

    service = TestService.new(:push, "data", "payload")
    service.http :adapter => [:test, stubs]

    service.http_get "https://example.com/   "
    http_call = service.http_calls[0]
    assert_equal "https://example.com/", http_call[:request][:url]
    assert_equal "ok", http_call[:response][:body]
  end

  def test_http_post_url_strip
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.post("/") { |env| [200, {}, "ok"] }
    stubs.post("/   ") { |env| [200, {}, "nope"] }

    service = TestService.new(:push, "data", "payload")
    service.http :adapter => [:test, stubs]

    service.http_post "https://example.com/   "
    http_call = service.http_calls[0]
    assert_equal "https://example.com/", http_call[:request][:url]
    assert_equal "ok", http_call[:response][:body]
  end

  def test_json_encoding
    payload = {'unicodez' => "rtiaü\n\n€ý5:q"}
    json = @service.generate_json(payload)
    assert_equal payload, JSON.parse(json)
  end

  def test_config_boolean_true_helper
    svc = service(:push, "is_checked" => nil)
    refute svc.config_boolean_true?("is_checked")

    svc = service(:push, "is_checked" => 0)
    refute svc.config_boolean_true?("is_checked")

    svc = service(:push, "is_checked" => "0")
    refute svc.config_boolean_true?("is_checked")

    svc = service(:push, "is_checked" => 1)
    assert svc.config_boolean_true?("is_checked")

    svc = service(:push, "is_checked" => "1")
    assert svc.config_boolean_true?("is_checked")
  end

  def test_before_delivery
    @service.before_delivery do |url, payload, headers, params|
      headers['EDITED-IN-BEFORE-DELIVERY'] = true
      payload.replace("EDITED")
    end

    @stubs.post '/' do |env|
      assert_equal '/', env.url.to_s
      assert_equal 'EDITED', env[:body]
      assert_equal true, env[:request_headers]['Edited-In-Before-Delivery']
      [200, {'X-Test' => 'success'}, 'OK']
    end

    @service.http_post('/', payload.to_s)

    @service.http_calls.each do |env|
      assert_equal 200, env[:response][:status]
    end

    assert_equal 1, @service.http_calls.size
  end

  def test_multiple_before_delivery_callbacks
    @service.before_delivery do |url, payload, headers, params|
      headers['EDITED-IN-BEFORE-DELIVERY-1'] = true
    end

    @service.before_delivery do |url, payload, headers, params|
      headers['EDITED-IN-BEFORE-DELIVERY-2'] = true
    end

    @stubs.get '/' do |env|
      assert_equal true, env[:request_headers]['Edited-In-Before-Delivery-1']
      assert_equal true, env[:request_headers]['Edited-In-Before-Delivery-2']
      [200, {'X-Test' => 'success'}, 'OK']
    end

    @service.http_get('/')

    @service.http_calls.each do |env|
      assert_equal 200, env[:response][:status]
    end
  end

  def test_reset_pre_delivery_callbacks!
    @service.before_delivery do |url, payload, headers, params|
      headers['EDITED-IN-BEFORE-DELIVERY'] = true
      payload.replace("EDITED")
    end

    @stubs.post '/' do |env|
      assert_equal 'EDITED', env[:body]
      assert_equal true, env[:request_headers]['Edited-In-Before-Delivery']
      [200, {'X-Test' => 'success'}, 'OK']
    end

    @service.http_post('/', "desrever")
    @service.reset_pre_delivery_callbacks!

    @stubs.post '/' do |env|
      refute_equal 'EDITED', env[:body]
      refute_equal true, env[:request_headers]['Edited-In-Before-Delivery']
      [200, {'X-Test' => 'success'}, 'OK']
    end
  end

  def service(*args)
    super TestService, *args
  end
end
