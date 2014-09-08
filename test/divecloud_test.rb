require File.expand_path('../helper', __FILE__)

class DiveCloudTest < Service::TestCase
    include Service::HttpTestMethods


    def setup
      @stubs   = Faraday::Adapter::Test::Stubs.new
      @data  = { 'api_key' => 'Test_Api_Key', 'plan_id' => '833', 'creds_pass' => 'testtest', 'random_timing' => true, }
      @payload = { Service::StatusHelpers.sample_status_payload }
    end 
    
    def post
      @stubs.post "https://divecloud.nouvola.com/api/v1/plans/833/run" do |env|
        assert_equal "application/json", env[:request_headers]["Content-Type"]
        assert_equal "Test_Api_Key", env[:request_headers]['x-api'] 
        assert_equal "833", env[:params]["plan_id"]
        assert_equal JSON.generate({ :payload => @payload }), env[:body]
      end
      
      svc.receive_status
      @stubs.verify_stubbed_calls
    end
    


  def service_class
    Service::DiveCloud
  end


end