require File.expand_path('../helper', __FILE__)

class LechatTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    host = "api.lechat.im"
    path = "/rooms/ca584f3e2143a0c3eae7a89485aa7f634589ceb39c972361bdefe348812794b1/github"

    data = {
      'webhook_url' => "http://" + host + path
    }

    payload_example = push_payload() # from helper
    svc = service(data, payload_example)

    @stubs.post path do |env|

      assert_equal host, env[:url].host
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-type']

      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal "push", data['event_type']
      assert_equal payload_example, JSON.parse(data['payload'])
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::LeChat
  end
end

