class Service::GithubPendingStatus < Service
  string :username
  password :password
  
  white_list :username
  
  maintained_by :github => "jtrinklein"
  
  default_events :push
  
  def receive_push
    if data['username'].to_s.empty?
      raise_config_error "Needs a username"
    end
    
    if data['password'].to_s.empty?
      raise_config_error "Needs a password"
    end
    
    http.url_prefix = = 'https://api.github.com/' + payload['repository']['owner']['name'] + '/' + payload['repository']['name'] + '/statuses/'
    
    http.basic_auth data['username'].to_s, data['password'].to_s
    
      #set the status of the newly created commit to pending
      res = http_post payload['after'], '{"status":"pending"}'
      
      case res.status
        when 200..299
        when 403, 401, 422 then raise_config_error("Invalid credentials")
        when 404, 301, 302 then raise_config_error("Invalid URL")
        else raise_config_error("HTTP: #{res.status}")
      end
    end
  end
end