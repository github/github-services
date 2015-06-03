class Service::IBMDevOpsServices < Service::HttpPost
  title 'IBM Bluemix DevOps Services'
  string :ibm_login
  password :ibm_password
  string :override_server_url
  white_list :ibm_login
  
  default_events :push

  # annotate this service
  url "http://hub.jazz.net"
  logo_url "https://hub.jazz.net/manage/web/com.ibm.team.jazzhub.web/graphics/HomePage/Powered-by-JH_white.png"
  supported_by :web => "https://hub.jazz.net/support", :email => "hub@jazz.net", :twitter => "@JazzHub"
  
  def receive_push
    username = required_config_value('ibm_login')
    password = required_config_value('ibm_password')
    override_server_url = data['override_server_url']
    server_url = (override_server_url.nil? || override_server_url.empty? ? "https://hub.jazz.net/manage" : override_server_url)
    post_url = "#{server_url}/processGitHubPayload?auth_type=ibmlogin"
    @request = {:ibm_login => username, :server_url => server_url, :url => post_url}
    @response = deliver post_url
    verify_post_response
  end
  
  def verify_post_response
    case @response.status
      when 200, 201, 304
        # OK
      when 401 then
        raise_config_error("Authentication failed for #{@request[:ibm_login]}: Status=#{@response.status}, Message=#{@response.body}")
      when 403 then
        raise_config_error("Authorization failure: Status=#{@response.status}, Message=#{@response.body}")
      when 404 then
        raise_config_error("Invalid git repo URL provided: Status=#{@response.status}, Message=#{@response.body}")
      else
        raise_config_error("HTTP Error: Status=#{@response.status}, Message=#{@response.body}")
    end
  end
  
end
