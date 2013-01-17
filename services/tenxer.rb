class Service::Tenxer < Service

  url "https://www.tenxer.com"
  logo_url "https://www.tenxer.com/static.b58bf75/image/touch-icon-144.png"

  maintained_by :github => 'tenxer'
  supported_by :web => 'http://www.tenxer.com/faq',
    :email => 'support@tenxer.com'
    
  def receive_event
    url = "https://www.tenxer.com/updater/githubpubsubhubbub/"
    res = http_post url, {'payload' => JSON.generate(payload)},
      {'X_GITHUB_EVENT' => event.to_s}
    if res.status != 200
      raise Error, "Error sending event to tenXer. Status: " +
        res.status.to_s + ": " + res.body
    end    
  end
end
