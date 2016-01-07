class Service::WindowsAzure < Service::HttpPost
  string :hostname, :username, :password

  white_list :hostname, :username

  default_events :push

  url "https://www.windowsazure.com/"
  logo_url "https://www.windowsazure.com/css/images/logo.png"

  maintained_by :github => "suwatch",
    :twitter => "@suwat_ch"

  supported_by :web => "https://github.com/projectkudu/kudu/wiki",
    :email => "davidebb@microsoft.com",
    :twitter => "@davidebbo"

  def receive_event
    hostname = required_config_value("hostname").to_s.strip
    username = required_config_value("username").to_s.strip
    password = required_config_value("password").to_s.strip
    
    raise_config_error "Invalid hostname" if hostname.empty?
    raise_config_error "Invalid username" if username.empty?
    raise_config_error "Invalid password" if password.empty?
    
    http.ssl[:verify] = false
    http.headers['X-GitHub-Event'] = event.to_s
    
    http.basic_auth(username, password)

    url = "https://#{hostname}:443/deploy?scmType=GitHub"
    
    res = deliver url
    raise_config_error "Invalid HTTP Response: #{res.status}" if res.status < 200 || res.status >= 400
  end
  
  def original_body
    payload
  end

  def default_encode_body
    encode_body_as_form
  end

  def encode_body_as_form
    http.headers["content-type"] = "application/x-www-form-urlencoded"
    Faraday::Utils.build_nested_query(
      http.params.merge(:payload => generate_json(original_body)))
  end
end
