class Service::Tenxer < Service
  self.title = 'tenXer'
  url "https://www.tenxer.com"
  logo_url "https://www.tenxer.com/static.b58bf75/image/touch-icon-144.png"

  maintained_by :github => 'tenxer'
  supported_by :web => 'http://www.tenxer.com/faq',
    :email => 'support@tenxer.com'

  default_events Service::ALL_EVENTS

  def receive_event
    url = "https://www.tenxer.com/updater/githubpubsubhubbub/"
    res = http_post url, {'payload' => generate_json(payload)},
      {'X_GITHUB_EVENT' => event.to_s}
    if res.status != 200
      raise Error, "Error sending event to tenXer. Status: " +
        res.status.to_s + ": " + res.body
    end
  end
end
