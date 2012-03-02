class Service::TeamCity < Service
  string   :base_url, :build_type_id, :username
  password :password

  def receive_push
    # :(
    http.ssl[:verify] = false

    http.url_prefix = data['base_url']
    http.basic_auth data['username'], data['password']
    build_type_ids = data['build_type_id']
    build_type_ids.split(",").each{|build_type_id| 
      res = http_get "httpAuth/action.html", :add2Queue => build_type_id
      case res.status
        when 200..299
        when 403, 401, 422 then raise_config_error("Invalid credentials")
        when 404, 301, 302 then raise_config_error("Invalid TeamCity URL")
        else raise_config_error("HTTP: #{res.status}")
      end
    }
  rescue SocketError => e
    raise_config_error "Invalid TeamCity host name" if e.to_s =~ /getaddrinfo: Name or service not known/
    raise
  end
end
