require 'test/unit'
require 'pp'
require File.expand_path('../../config/load', __FILE__)
Service.load_services

class Service::TestCase < Test::Unit::TestCase
  ALL_SERVICES = Service.services.dup

  def test_default
  end

  def service(klass, event_or_data, data, payload=nil)
    event = nil
    if event_or_data.is_a?(Symbol)
      event = event_or_data
    else
      payload = data
      data    = event_or_data
      event   = :push
    end

    service = klass.new(event, data, payload)
    service.http :adapter => [:test, @stubs]
    service
  end

  def basic_auth(user, pass)
    "Basic " + ["#{user}:#{pass}"].pack("m*").strip
  end

  def push_payload
    Service::PushHelpers.sample_payload
  end
  alias payload push_payload

  def pull_payload
    Service::PullRequestHelpers.sample_payload
  end

  def issues_payload
    Service::IssueHelpers.sample_payload
  end

  def basic_payload
    Service::HelpersWithMeta.sample_payload
  end
end

module Service::HttpTestMethods
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service(data={
      'url' => 'http://monkey:secret@abc.com/foo/?a=1',
      'secret' => ''
    }, payload)

    @stubs.post "/foo/" do |env|
      assert_equal 'Basic bW9ua2V5OnNlY3JldA==', env[:request_headers]['authorization']
      assert_match /json/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_nil env[:url].port
      params = Faraday::Utils.parse_nested_query(env[:url].query)
      assert_equal({'a' => '1'}, params)

      body = JSON.parse(env[:body])
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      assert_equal payload, body['payload']

      assert_nil env[:request_headers]['X-Hub-Signature']
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_push_with_ssl
    svc = service(data={
      'url' => 'https://abc.com/foo',
      'secret' => ''
    }, payload)

    @stubs.post "/foo/" do |env|
      assert_equal 'abc.com', env[:url].host
      assert_nil env[:url].port
    end
  end

  def test_push_without_scheme
    svc = service({
      'url' => 'abc.com/foo/?a=1',
      'secret' => ''
    }, payload)

    @stubs.post "/foo/" do |env|
      assert_equal 'abc.com', env[:url].host
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_push_as_json
    svc = service({
      'url'          => 'http://monkey:secret@abc.com/foo?a=1',
      'content_type' => 'json'
    }, payload)

    @stubs.post "/foo" do |env|
      assert_equal 'Basic bW9ua2V5OnNlY3JldA==', env[:request_headers]['authorization']
      params = Faraday::Utils.parse_nested_query(env[:url].query)
      assert_equal({'a' => '1'}, params)
      assert_match /json/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_nil env[:request_headers]['X-Hub-Signature']

      body = JSON.parse(env[:body])
      assert_equal payload, body['payload']
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_push_as_json_with_secret
    svc = service({
      'url'          => 'http://abc.com/foo',
      'secret'       => 'monkey',
      'content_type' => 'json'
    }, payload)

    @stubs.post "/foo" do |env|
      assert_nil env[:request_headers]['authorization']
      assert_match /json/, env[:request_headers]['content-type']
      assert_equal 'abc.com', env[:url].host
      assert_equal 'sha1='+OpenSSL::HMAC.hexdigest(Service::Web::HMAC_DIGEST,
                                        'monkey', env[:body]),
        env[:request_headers]['X-Hub-Signature']

      body = JSON.parse(env[:body])
      assert_equal payload, body['payload']
      [200, {}, '']
    end

    svc.receive_event
  end

  def test_log_message
    data = {
      'url'          => 'http://abc.com/def',
      'secret'       => 'monkey',
      'content_type' => 'json'
    }

    svc = service(data, payload)
    assert_match /^\[[^\]]+\] 200 httppost\/push \{/, svc.log_message(200)
  end

  def service(event_or_data, data, payload = nil)
    super(service_class, event_or_data, data, payload)
  end

  def service_class
    raise NotImplementedError
  end
end

