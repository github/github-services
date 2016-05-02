class Service::AgileZen < Service
  string :api_key, :project_id, :branches
  white_list :project_id, :branches

  def receive_push
    raise_config_error "Missing 'api_key'"    if data['api_key'].to_s == ''
    raise_config_error "Missing 'project_id'" if data['project_id'].to_s == ''

    branches = data['branches'].to_s.split(/\s+/)
    ref = payload["ref"].to_s
    return unless branches.empty? || branches.include?(ref.split("/").last)

    http.headers['X-Zen-ApiKey'] = data['api_key']
    http.headers['Content-Type'] = 'application/json'

    res = http_post "https://agilezen.com/api/v1/projects/#{data['project_id']}/changesets/github",
      generate_json(payload)

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end
