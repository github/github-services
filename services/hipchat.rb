class Service::HipChat < Service
  string :auth_token, :room
  boolean :notify

  def receive_push
    # make sure we have what we need
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''
    raise_config_error "Missing 'room'" if data['room'].to_s == ''

    http.ssl[:verify] = false
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
