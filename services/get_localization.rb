class Service::GetLocalization < Service
  string :project_name, :project_token

  def receive_push
    project_name = data['project_name']
    project_token = data['project_token']

    http.ssl[:verify] = false
    res = http_post "https://getlocalization.com/services/github/notify/#{project_name}/#{project_token}/",
      :payload => payload.to_json

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end


