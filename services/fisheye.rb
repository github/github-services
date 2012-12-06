class Service::Fisheye < Service
  def receive_push

    repository_name = payload['repository']['name']
    url_base = data['url_base']
    token = data['token']
    custom_repository_name = data['custom_repository_name']

    if custom_repository_name.to_s.strip.length != 0
      repository_name = custom_repository_name
    end

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
        raise_config_error("Unknown error")
    end
  end
end

