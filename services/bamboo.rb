class Service::Bamboo < Service
  def receive_push
    verify_config
    authenticated { |token| trigger_build(token) }
  rescue SocketError => e
    if e.to_s =~ /getaddrinfo: Name or service not known/
      raise_config_error("Invalid Bamboo host name")
    else
      raise
    end
  end

  def trigger_build(token)
    res = http_post "api/rest/executeBuild.action",
      "auth=#{CGI.escape(token)}&buildKey=#{CGI.escape(build_key)}"
    msg = XmlSimple.xml_in(res.body)
    raise_config_error msg["error"] if msg["error"]
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
    faraday.url_prefix = base_url
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
