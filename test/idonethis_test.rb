require File.expand_path('../helper', __FILE__)

class IDoneThisTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_team_name = "team-name"
    test_token = "0123456789abcde"

    data = {
      'team_name' => test_team_name,
      'token' => test_token
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/gh/#{test_team_name}/" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "idonethis.com"
      assert_equal env[:request_headers]['Authorization'], "Token #{test_token}"
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::IDoneThis
  end
end
