class Service::Distiller < Service
  self.title = "Distiller"
  url "https://distiller.io"
  logo_url "https://www.distiller.io/favicon.ico"

  maintained_by :github => 'travis'
  supported_by  :web => 'https://distiller.io/chat',
    :email => 'help@distiller.io'

  default_events :push

  def receive_event
    http.headers['content-type'] = 'application/x-www-form-urlencoded'
    http_post distiller_url,
      "payload" => generate_json(payload),
      "event_type" =>  generate_json(:event_type => event)
  end

  private

  def distiller_url
    "https://www.distiller.io/hooks/github"
  end
end
