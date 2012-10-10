class Service::Asana < Service
  string :auth_token

  def receive_push
    # make sure we have what we need
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''

    payload['commits'].each do |commit|
      commit_id = commit['id']
      message   = commit["message"]
      files     = commit["removed"] | commit["added"] | commit["modified"]

      http.basic_auth(data['auth_token'], "")
      http.headers['X-GitHub-Event'] = event.to_s

      res = http_post "https://app.asana.com/api/1.0/tasks/2113734324548/stories", "text=" + message
      if res.status < 200 || res.status > 299
        raise_config_error
      end
    end
  end
end
