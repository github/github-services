require File.expand_path('../helper', __FILE__)

class RationalTeamConcertTest < Service::TestCase
  def setup
    @stubs= Faraday::Adapter::Test::Stubs.new

    @stubs.post "/processGitHubPayload" do |env|
      assert_common_headers env
      assert_common_oslc_headers env
      @Pushes += 1
      [201, {}, '']
    end
    
    @stubs.get "/jazz/authenticated/identity" do |env|
      assert_common_headers env
      cookie= env[:request_headers]['Cookie'] == nil ? cookie1 : cookie2;
      [201, {"X-com-ibm-team-repository-web-auth-msg" => "authrequired", "set-cookie" => cookie}, '']
    end
    
    @stubs.post "/jazz/authenticated/j_security_check"  do |env|
      assert_common_headers env
      assert_equal 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      assert_equal cookie1, env[:request_headers]['Cookie']
      [201, {}, oslc_json_response]
    end
  end

  def test_push_updates
    modified_payload = payload.clone()
    modified_payload['commits'][0]['message'] << "\n[51] Some message"
    modified_payload['commits'][1]['message'] << "\n[31] clean up "
    modified_payload['commits'][2]['message'] << "\n[1] Closes tracker item 1"

    svc = service(
      {'server_url' => 'https://foo.com/jazz', 
       'username' => username, 
       'password' => password,
       'project_area_uuid' => '_UIID',
       'basic_authentication' => false},
        modified_payload)
    svc.receive_push

    assert_equal 1, @Pushes
  end

  def assert_common_headers env
    assert_equal username, env[:request_headers]['X-com-ibm-team-userid']
    assert_equal 'foo.com', env[:url].host
  end

  def username
    return 'test_user' 
  end

  def password
    return 'test_pass'
  end

  def cookie1
    return "JSESSIONID=abcd123456"
  end

  def cookie2
    return "JSESSIONID=abcd12345678910"
  end
  
  def service(*args)
    super Service::RationalJazzHub, *args
  end
end

