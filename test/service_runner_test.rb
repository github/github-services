require File.expand_path('../helper', __FILE__)

class ServiceRunnerTest < Test::Unit::TestCase
  class TestService < Service
    class << self
      attr_accessor :tested
    end

    def receive_booya
      self.class.tested << self
    end
  end

  def setup
    TestService.tested = []
    @runner = Service::Runner.new
  end

  def test_call
    data = {'a' => 1}
    payload = {'b' => 1}

    resp = @runner.call(TestService, 'booya', data, payload)
    assert_equal 200, resp.status
    assert_equal 'OK', resp.message

    assert svc = TestService.tested.shift
    assert_nil TestService.tested.first

    assert_equal data, svc.data
    assert_equal payload, svc.payload
    assert_equal :booya, svc.event
  end
end

