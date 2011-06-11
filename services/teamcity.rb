class Service::TeamCity < Service
  self.hook_name = :team_city

  def receive_push
    http.url_prefix = data['base_url']
    http.basic_auth data['username'], data['password']
    res = http_get "httpAuth/action.html", :add2Queue => data['build_type_id']
    case res.status
      when 200..299
      when 403, 401, 422 then raise_config_error("Invalid credentials")
      when 404, 301, 302 then raise_config_error("Invalid TeamCity URL")
      else raise_config_error("HTTP: #{res.status}")
    end
  rescue SocketError => e
    raise_config_error "Invalid TeamCity host name" if e.to_s =~ /getaddrinfo: Name or service not known/
    raise
  end
end
