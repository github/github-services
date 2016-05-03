require File.expand_path("../helper", __FILE__)

class WindowsAzureTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push
    
    data = {
      "hostname" => "test.scm.azurewebsites.net",
      "username" => "test_user",
      "password" => "test_pwd"
    }
            
    svc = service(data, payload)
    
    @stubs.post "/deploy?scmType=GitHub" do |env|
      assert_equal 'push', env[:request_headers]['x-github-event']
      assert_equal 'Basic dGVzdF91c2VyOnRlc3RfcHdk', env[:request_headers]['authorization']
      assert_equal env[:url].host, data['hostname']
      assert_match /form/, env[:request_headers]['content-type']
      params = Faraday::Utils.parse_nested_query(env[:url].query)
      assert_equal({'scmType' => 'GitHub'}, params)
      body = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal 'GitHub', body['scmType']
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv
      assert_nil env[:request_headers]['X-Hub-Signature']
      assert_equal 'GitHub', body['scmType']
      [200, {}, ""]
    end

    svc.receive_event
  end

  def service_class
    Service::WindowsAzure
  end
        
end

