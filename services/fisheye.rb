class Service::Fisheye < Service

  string  :url_base, :token, :repository_name

  def receive_push

    verify_config

    http.headers['X-Api-Key'] = token

    url = "%s/rest-service-fecru/admin/repositories-v1/%s/scan" % [url_base, repository_name]

    res = http_post url

    handle_response(res)

  end

  def handle_response(response)
    case response.status
      when 200
        "Ok"
      when 401
        raise_config_error("Invalid token")
      when 404
        raise_config_error("Invalid repository name")
      else
        msg = "#{url_base}, repository: #{repository_name} with token: #{token.to_s.strip.length != 0}"
        raise_config_error("Error occurred: #{response.status} when connecting to: #{msg}")
    end
  end

  def verify_config
    %w(url_base token repository_name).each do |var|
      raise_config_error "Missing configuration: #{var}" if send(var).to_s.empty?
    end
  end

  def repository_name
    @repository_name ||= (data['custom_repository_name'].to_s.strip.length != 0) ? data['custom_repository_name'] : payload['repository']['name']
  end

  def url_base
    @url_base ||= data['url_base']
  end

  def token
    @token ||= data['token']
  end

end

