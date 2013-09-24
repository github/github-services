require File.expand_path('../helper', __FILE__)

class CoffeeDocInfoTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    @stubs.post "/checkout" do |env|
      assert_equal 'coffeedoc.info', env[:url].host
      body = JSON.parse(env[:body])
      assert_equal 'push', body['event']
      assert_equal 'test', body['payload']['commits'][0]['id']
      [200, {}, '']
    end

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service({}, payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::CoffeeDocInfo
  end
end

