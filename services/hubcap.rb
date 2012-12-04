class Service::Hubcap < Service
  def receive_push
    http_post "http://hubcap.it/webhook",
      :payload => payload.to_json
  end
end
