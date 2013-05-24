class Service::LeChat < Service::HttpPost
  string :webhook_url

  # include 'webhook_url' in the debug logs
  white_list :webhook_url

  default_events Service::ALL_EVENTS

  url "https://lechat.im/"

  maintained_by :github => 'JLarky'

  supported_by :email => 'support@lechat.im'

  def receive_event
    webhook_url = required_config_value('webhook_url')

    res = deliver webhook_url, :content_type => 'form'

    if res.status < 200 || res.status > 299
      raise_missing_error "Unexpected response code:#{res.status}"
    end
  end

  def original_body
    {:payload => generate_json(payload), :event => event.to_s}
  end
end
