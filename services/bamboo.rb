class Service::Bamboo < Service
  string   :base_url, :build_key, :username
  password :password

  def receive_push
    verify_config
    branch = payload['ref']
    authenticated { |token| trigger_build(token, branch) }
  rescue SocketError => e
    if e.to_s =~ /getaddrinfo: Name or service not known/
      raise_config_error("Invalid Bamboo host name")
    else
      raise
    end
  end

  def trigger_build(token, ref)
    #Split build_keys by comma
    build_key.split(',').each { |branchKey|
    
        #See if the split result is just a key or a branch:key 
        parts = branchKey.split(':')
        key = parts[0]
        if (parts.length == 2)
            branch = parts[0]
            key = parts[1]
            
            #Has a branch, verify it matches the branch for the commit
            if (branch != ref.split("/").last)
                next                
            end
        end
        
        #Start the build
        res = http_post "api/rest/executeBuild.action",
          "auth=#{CGI.escape(token)}&buildKey=#{CGI.escape(key)}"
        msg = XmlSimple.xml_in(res.body)
        raise_config_error msg["error"] if msg["error"]
    }
  end

  def authenticated
    token = login
    yield token
  ensure
    logout(token)
  end

  def login
    res = http_post "api/rest/login.action",
      "username=#{CGI.escape(username)}&password=#{CGI.escape(password)}"
    case res.status
      when 200..204
        XmlSimple.xml_in(res.body)['auth'].first
      when 403, 401, 422 then raise_config_error("Invalid credentials")
      when 404, 301 then raise_config_error("Invalid Bamboo project URL")
    end
  end

  def logout(token)
    return unless token
    http_post "api/rest/logout.action", "auth=#{CGI.escape(token)}"
  end

  def verify_config
    %w(base_url build_key username password).each do |var|
      raise_config_error "Missing configuration: #{var}" if send(var).to_s.empty?
    end
    http.ssl[:verify] = false
    http.url_prefix   = base_url
  end

  def base_url
    @base_url ||= data['base_url'].gsub(/\/$/, '')
  end

  def build_key
    @build_key ||= data['build_key']
  end

  def username
    @username ||= data['username']
  end

  def password
    @password ||= data['password']
  end
end
