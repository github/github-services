class Service::Tenxer < Service
  url "https://www.tenxer.com"
  logo_url "https://www.tenxer.com/static.b58bf75/image/touch-icon-144.png"
  maintained_by :github => 'tenxer'
  supported_by :web => 'http://www.tenxer.com/faq',
    :email => 'support@tenxer.com'

  string :api_key

  def receive_event
    # make sure we have what we need
    raise_config_error "Missing 'api_key'" if data['api_key'].to_s == ''

    url = "https://www.tenxer.com/updater/githubpubsubhubbub/"
    res = http_post url, 
      {'api_key' => data['api_key'],
        'payload' => JSON.generate(payload)},
      {'X_GITHUB_EVENT' => event.to_s}
    if res.status != 200
      raise Error, "Error sending event to tenXer. Status: " +
        res.status.to_s + ": " + res.body
    end
  end
end
