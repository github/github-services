require File.expand_path('../helper', __FILE__)

class CIATest < Service::TestCase
  def setup
    @messages = []
    @server   = lambda do |method, message|
      @messages << [method, message]
    end
  end

  def test_push
    svc = service({'project' => 'abc', 'long_url'=>1}, payload)
    svc.xmlrpc_server = @server
    svc.receive_push

    assert msg = @messages.shift
    assert_equal 'hub.deliver', msg.first
    assert_match '06f63b43050935962f84fe54473a7c5de7977325', msg.last
    assert msg = @messages.shift
    assert msg = @messages.shift
    assert_nil @messages.shift
  end

  def service(*args)
    super Service::CIA, *args
  end
end



