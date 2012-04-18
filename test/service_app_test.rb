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
    assert_nil svc.meta
  end

  def test_nagios_check
    get '/'
    assert_equal 'ok', last_response.body
  end

  def app
    Service::App
  end
end
