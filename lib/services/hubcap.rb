class Service::Hubcap < Service
  def receive_push
    http_post "http://hubcap.it/webhook",
      :payload => generate_json(payload)
  end
end
