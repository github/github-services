require File.expand_path('../helper', __FILE__)

class DeployervcTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    test_deployment_address = 'https://emre.deployer.vc/#/deployment/1'
    test_api_token = 'this_is_a_test_token'

    data = {
        'deployment_address' => test_deployment_address,
        'api_token' => test_api_token
    }

    payload = {'commits'=>[{'id'=>'test'}]}
    svc = service(data, payload)

    @stubs.post '/api/v1/deployments/deploy/1' do |env|
      body = JSON.parse(env[:body])

      assert_equal env[:url].host, 'emre.deployer.vc'
      assert_equal env[:request_headers]['X-Deployervc-Token'], test_api_token
      assert_equal '', body['revision']
      [200, {}, '']
    end

    svc.receive_event
    @stubs.verify_stubbed_calls
  end

  def service_class
    Service::Deployervc
  end
end