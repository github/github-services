class Service::GenericNotifier < Service
  default_events *Service::ALL_EVENTS

  maintained_by :github => 'rca'
  supported_by :email => 'roberto@baremetal.io'

  string :url
  boolean :verify_ssl

  # add a boolean for all the supported events
  Service::ALL_EVENTS.each do |event|
    boolean event
  end

  def receive_event
    return unless data[@event.to_s]

    raise_config_error "Missing URL" if data['url'].to_s.empty?

    if !data["verify_ssl"]
      http.ssl[:verify] = false
    end

    http_post data["url"], :event => @event, :payload => payload.to_json
  end
end
