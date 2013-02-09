class Service::GenericNotifier < Service
  default_events *Service::ALL_EVENTS

  maintained_by :github => 'rca'
  supported_by :email => 'roberto@baremetal.io'

  string :url

  # add a boolean for all the supported events
  Service::ALL_EVENTS.each do |event|
    boolean event
  end

  def receive_event
    return unless data[@event.to_s]

    raise_config_error "Missing URL" if data['url'].to_s.empty?

    payload['event'] = @event
    
    http.ssl[:verify] = false
    http_post data["url"], :payload => payload.to_json
  end
end
