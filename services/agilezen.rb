class Service::AgileZen < Service
  string :api_key, :project_id

  def receive_push
    raise_config_error "Missing 'api_key'"    if data['api_key'].to_s == ''
    raise_config_error "Missing 'project_id'" if data['project_id'].to_s == ''

    http.headers['X-Zen-ApiKey'] = data['api_key']

    res = http_post "https://agilezen.com/api/v1/projects/#{data['project_id']}/changesets/github",
      JSON.generate(payload)
      
    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end
