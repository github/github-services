require File.expand_path('../helper', __FILE__)

class KatoTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    host = "api.kato.im"
    path = "/rooms/ca584f3e2143a0c3eae7a89485aa7f634589ceb39c972361bdefe348812794b1/github"

    data = {
      'webhook_url' => "http://" + host + path
    }

    payload_example = push_payload() # from helper
    svc = service(data, payload_example)

    @stubs.post path do |env|

      assert_equal host, env[:url].host
      assert_equal 'application/json', env[:request_headers]['Content-type']

      data = JSON.parse(env[:body])
      assert_equal "push", data['event']
      assert_equal payload_example, data['payload']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Kato
  end
end

