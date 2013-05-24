class Service::LeChat < Service
  string :webhook_url

  # include 'webhook_url' in the debug logs
  white_list :webhook_url

  default_events Service::ALL_EVENTS

  url "https://lechat.im/"

  maintained_by :github => 'JLarky'

  supported_by :email => 'support@lechat.im'

  def receive_event
    if data['webhook_url'].to_s.empty?
      raise_config_error "webhook_url url is missing"
    end

    http.headers['content-type'] = 'application/x-www-form-urlencoded'
    res = http_post data['webhook_url'],
      "payload" => generate_json(payload),
      "event_type" => event

    if res.status < 200 || res.status > 299
      raise_config_error("Unexpected response code:#{res.status}")
    end
  end
end
