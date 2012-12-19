class Service::FishEye < Service

  string  :FishEye_Base_URL, :REST_API_Token, :FishEye_Repository_Name
  white_list :FishEye_Base_URL, :FishEye_Repository_Name

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
        raise_config_error("Invalid REST API Token")
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
    @FishEye_Repository_Name ||= (data['FishEye_Repository_Name'].to_s.strip.length != 0) ? data['FishEye_Repository_Name'] : payload['repository']['name']
  end

  def url_base
    @FishEye_Base_URL ||= data['FishEye_Base_URL']
  end

  def token
    @REST_API_Token ||= data['REST_API_Token']
  end

end

