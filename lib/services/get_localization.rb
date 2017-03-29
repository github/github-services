class Service::GetLocalization < Service
  string :project_name
  password :project_token
  white_list :project_name

  def receive_push
    project_name = data['project_name']
    project_token = data['project_token']

    res = http_post "https://www.getlocalization.com/services/github/notify/#{project_name}/#{project_token}/",
      :payload => generate_json(payload)

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end


