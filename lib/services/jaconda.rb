class Service::Jaconda < Service
  string  :subdomain, :room_id, :room_token
  boolean :digest
  white_list :subdomain, :room_id

  default_events :commit_comment, :download, :fork, :fork_apply, :gollum,
    :issues, :issue_comment, :member, :public, :pull_request, :push, :watch

  def receive_event
    raise_config_error "Missing 'subdomain'" if data['subdomain'].to_s.empty?
    raise_config_error "Missing 'room_id'"   if data['room_id'].to_s.empty?

    http.basic_auth data['room_token'], 'X'

    res = http_post "https://#{data['subdomain']}.jaconda.im/api/v2/rooms/#{data['room_id']}/notify/github.json",
      :payload => generate_json(payload),
      :digest => data['digest'],
      :event => event

    if res.status < 200 || res.status > 299
      raise_config_error "#{res.status}: #{res.body}"
    end
  end
end

