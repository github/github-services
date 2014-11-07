require File.expand_path('../helper', __FILE__)

class RDocInfoTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    @stubs.post "/checkout" do |env|
      assert_equal 'www.rubydoc.info', env[:url].host
      body = JSON.parse(env[:body])
      assert_equal 'push', body['event']
      assert_equal 'test', body['payload']['repository']['id']
      [200, {}, '']
    end

    payload = { 'repository' => { 'id' => 'test' }}
    svc = service({}, payload)
    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  private

  def service_class
    Service::RDocInfo
  end
end

