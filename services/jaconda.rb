class Service::Jaconda < Service
  def receive_push
    raise_config_error "Missing 'subdomain'"  if data['subdomain'].to_s == ''
    raise_config_error "Missing 'room_id'"    if data['room_id'].to_s == ''

    http.basic_auth data['room_token'], 'X'

    res = http_post "https://#{data['subdomain']}.jaconda.im/api/v2/rooms/#{data['room_id']}/notify/github.json",
      :payload => JSON.generate(payload),
      :digest => data['digest']

    if res.status < 200 || res.status > 299
      raise_config_error "#{res.status}: #{res.body}"
    end
  end
end
