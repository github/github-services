require File.expand_path('../helper', __FILE__)

class RationalTeamConcertTest < Service::TestCase
  def setup
    @stubs= Faraday::Adapter::Test::Stubs.new
    @WorkitemsCreated= 0;
    @WorkitemsUpdated= 0;

    @stubs.get "/jazz/resource/itemName/com.ibm.team.workitem.WorkItem/51?oslc.properties=oslc:discussedBy" do |env|
      assert_common_headers env
      assert_common_oslc_headers env
      [200, {}, oslc_json_response]
    end
    @stubs.get "/jazz/resource/itemName/com.ibm.team.workitem.WorkItem/31?oslc.properties=oslc:discussedBy" do |env|
      assert_common_headers env
      assert_common_oslc_headers env
      [200, {}, oslc_json_response]
    end
    @stubs.get "/jazz/resource/itemName/com.ibm.team.workitem.WorkItem/1?oslc.properties=oslc:discussedBy" do |env|
      assert_common_headers env
      assert_common_oslc_headers env
      [200, {}, oslc_json_response]
    end
    @stubs.post "/jazz/oslc/workitems/_UIID/rtc_cm:comments/oslc:comment" do |env|
      assert_common_headers env
      assert_common_oslc_headers env
      @WorkitemsUpdated += 1
      [201, {}, '']
    end
    @stubs.post "/jazz/oslc/contexts/_UIID/workitems/defect" do |env|
      assert_common_headers env
      assert_common_oslc_headers env
      @WorkitemsCreated += 1
      [201, {}, oslc_json_response]
    end
    @stubs.post "/jazz/oslc/contexts/_UIID/workitems/enhancement" do |env|
      assert_common_headers env
      assert_common_oslc_headers env
      @WorkitemsCreated += 1
      [201, {}, oslc_json_response]
    end
    @stubs.post "/jazz/oslc/contexts/_UIID/workitems/story" do |env|
      assert_common_headers env
      assert_common_oslc_headers env
      @WorkitemsCreated += 1
      [201, {}, oslc_json_response]
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

  def test_basic_authentication_push_updates

    @formAuthentication= false;
    modified_payload= payload.clone()
    modified_payload['commits'][0]['message'] << "\n[51] Some message"
    modified_payload['commits'][1]['message'] << "\n[31] clean up "
    modified_payload['commits'][2]['message'] << "\n[1] Closes tracker item 1"

    svc= service(
      {'server_url' => 'https://foo.com/jazz', 
       'username' => username, 
       'password' => password,
       'project_area_uuid' => '_UIID',
       'basic_authentication' => true},
        modified_payload)
    svc.receive_push

    assert_equal 0, @WorkitemsCreated
    assert_equal 3, @WorkitemsUpdated
  end

  def test_basic_authentication_create_new

    @formAuthentication= false;
    modified_payload = payload.clone()
    modified_payload['commits'][0]['message'] << "\n[defect] Some message"
    modified_payload['commits'][1]['message'] << "\n[enhancement] clean up "
    modified_payload['commits'][2]['message'] << "\n[story] Closes tracker item 1"

    svc = service(
      {'server_url' => 'https://foo.com/jazz', 
       'username' => username, 
       'password' => password,
       'project_area_uuid' => '_UIID',
       'basic_authentication' => true},
        modified_payload)
    svc.receive_push

    assert_equal 3, @WorkitemsCreated
    assert_equal 3, @WorkitemsUpdated
  end

  def test_form_authentication_push_updates

    @formAuthentication= true;
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

    assert_equal 0, @WorkitemsCreated
    assert_equal 3, @WorkitemsUpdated
  end

  def test_form_authentication_create_new

    @formAuthentication= true;
    modified_payload = payload.clone()
    modified_payload['commits'][0]['message'] << "\n[defect] Some message"
    modified_payload['commits'][1]['message'] << "\n[enhancement] clean up "
    modified_payload['commits'][2]['message'] << "\n[story] Closes tracker item 1"

    svc = service(
      {'server_url' => 'https://foo.com/jazz', 
       'username' => username, 
       'password' => password,
       'project_area_uuid' => '_UIID',
       'basic_authentication' => false},
        modified_payload)
    svc.receive_push

    assert_equal 3, @WorkitemsCreated
    assert_equal 3, @WorkitemsUpdated
  end

  def assert_common_headers env
    assert_equal username, env[:request_headers]['X-com-ibm-team-userid']
    assert_equal 'foo.com', env[:url].host
  end

  def assert_common_oslc_headers env
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal 'application/json', env[:request_headers]['accept']
      assert_equal '2.0', env[:request_headers]['oslc-core-version']
      assert_equal cookie2, env[:request_headers]['Cookie'] if @formAuthentication
      assert_equal "Basic " + Base64.encode64("#{username}:#{password}").gsub("\n", ""), env[:request_headers]['authorization'] if not @formAuthentication
  end

  def oslc_json_response
    return '{ 
              "oslc:discussedBy": { 
                "rdf:resource": "https://foo.com/jazz/oslc/workitems/_UIID/rtc_cm:comments" 
              } 
            }'
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
    super Service::RationalTeamConcert, *args
  end
end

