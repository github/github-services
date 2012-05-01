class Service::HipChat < Service
  string :auth_token, :room
  boolean :notify
  white_list :room

  default_events :push, :pull_request, :issues

  def receive_push
    # validate auth_token
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''

    # validate room
    raise_config_error "Missing 'room'" if data['room'].to_s == ''

    http.headers['X-GitHub-Event'] = event.to_s

    res = http_post "https://api.hipchat.com/v1/webhooks/github",
      :auth_token => data['auth_token'],
      :room_id => data['room'],
      :payload => JSON.generate(payload),
      :notify => data['notify'] ? 1 : 0
    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end
