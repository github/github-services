class Service::RationalJazzHub < Service::HttpPost
  string :username
  password :password
  string :override_server_url
  white_list :username

  def receive_push
    username = required_config_value('username')
    password = required_config_value('password')
    override_server_url = data['override_server_url']
    server_url = (override_server_url.nil? || override_server_url.empty? ? "https://hub.jazz.net/manage" : override_server_url)
    post_url = "#{server_url}/processGitHubPayload"
    @request = {:username => username, :server_url => server_url, :url => post_url}
    @response = deliver post_url
    verify_post_response
  end
  
  def verify_post_response
    case @response.status
      when 200, 201, 304
        # OK
      when 401, 403 then 
        raise_config_error("Authentication failed for #{@request[:username]}: Status=#{@response.status}, Message=#{@response.body}")
      when 404 then 
        raise_config_error("Invalid server URL provided #{@request[:server_url]}")
      else
        raise_config_error("HTTP Error: Status=#{@response.status}, Message=#{@response.body}")
    end
  end
  
end
