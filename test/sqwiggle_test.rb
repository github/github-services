require File.expand_path('../helper', __FILE__)

class SqwiggleTest < Service::TestCase
  include Service::HttpTestMethods

  def test_default_room_push

    data = {
      'token' => 'some_token'
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "integrations/github" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "api.sqwiggle.com"
      assert_equal basic_auth('some_token', 'X'), env[:request_headers][:authorization]
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def test_specified_room_push
    data = {
      'token' => 'some_token',
      'room' => 'some_room'
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "integrations/github/some_room" do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, "api.sqwiggle.com"
      assert_equal basic_auth('some_token', 'X'), env[:request_headers][:authorization]
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Sqwiggle
  end
end


