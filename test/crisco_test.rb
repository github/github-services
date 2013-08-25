require File.expand_path('../helper', __FILE__)

class CriscoTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_crisco_url = "http://custom-crisco.herokuapp.com/"

    data = {
      'crisco_url' => test_crisco_url
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/webhook" do |env|
      body = JSON.parse(env[:body])
      assert_equal env[:url].host, "custom-crisco.herokuapp.com"
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_match 'guid-', body['guid']
      assert_equal data, body['config']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end


  def test_push_default_url
    test_crisco_url = ""

    data = {
      'crisco_url' => test_crisco_url
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post "/webhook" do |env|
      body = JSON.parse(env[:body])
      assert_equal env[:url].host, "crisco-review.herokuapp.com"
      assert_equal 'test', body['payload']['commits'][0]['id']
      assert_match 'guid-', body['guid']
      assert_equal 'push', body['event']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Crisco
  end
end

