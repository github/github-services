require File.expand_path('../helper', __FILE__)

class DiveCloudTest < Service::TestCase
    

    def setup
      @stubs = Faraday::Adapter::Test::Stubs.new
      @data = { 'api_key' => 'Test_Api_Key', 'plan_id' => '833', 'creds_pass' => 'testtest', 'random_timing' => true, }
      @payload =  { 'status' => 'success' } 
    end

    def test_deployment_status

      @stubs.post "/api/v1/plans/833/run" do |env|
        assert_equal "application/json", env[:request_headers]["Content-Type"]
        assert_equal "Test_Api_Key", env[:request_headers]['x-api']
        [200, {}, '']
      end

      svc = service(:deployment_status, @data, @payload)
      svc.receive_deployment_status
 
    end

     def service(*args)
      super Service::DiveCloud, *args
    end


end