require File.expand_path('../helper', __FILE__)
require 'rack/test'

class ServiceAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  class TestAppService < Service
    class << self
      attr_accessor :tested
    end

    def receive_booya
      self.class.tested << self
    end

    Service::App.service(self)
  end

  def setup
    TestAppService.tested = []
  end

  def test_http_post
    data = {'a' => 1}
    payload = {'b' => 2}
    post "/testappservice/booya",
      :data => JSON.generate(data),
      :payload => JSON.generate(payload)
    assert_equal 200, last_response.status

    assert svc = TestAppService.tested.shift
    assert_nil TestAppService.tested.first

    assert_equal data, svc.data
    assert_equal payload, svc.payload
    assert_equal :booya, svc.event
  end

  def test_json_post
    data = {'a' => 1}
    payload = {'b' => 2}

    header 'Content-Type', Service::App::JSON_TYPE
    post "/testappservice/booya", {},
      :input => JSON.generate(:data => data, :payload => payload)

    assert_equal 200, last_response.status

    assert svc = TestAppService.tested.shift
    assert_nil TestAppService.tested.first

    assert_equal data, svc.data
    assert_equal payload, svc.payload
    assert_equal :booya, svc.event
  end

  def test_nagios_check
    get '/'
    assert_equal 'ok', last_response.body
  end

  def test_service_hook_names
    Service::TestCase::ALL_SERVICES.each do |svc|
      get "/#{svc.hook_name}"
      assert_equal svc.title, last_response.body
    end
  end

  def app
    Service::App
  end
end
