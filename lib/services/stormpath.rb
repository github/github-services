class Service::Stormpath < Service::HttpPost

  string   :api_key_id
  password :api_key_secret
  white_list :api_key_id

  url "https://stormpath.com"

  maintained_by :github => "lhazlewood"

  default_events :push

  logo_url "https://api.stormpath.com/assets/images/logo_nav.png"

  supported_by :web => 'https://support.stormpath.com',
               :email => 'support@stormpath.com',
               :twitter => '@goStormpath'

  def receive_event

    id = required_config_value('api_key_id')
    secret = required_config_value('api_key_secret')

    http.basic_auth id.to_s, secret.to_s

    res = deliver api_url

    case res.status
      when 200..299
      when 401 then raise_config_error("Authentication with a valid API Key is required. The provided Api Key Id/Secret is invalid.")
      else raise_config_error("HTTP: #{res.status}")
    end

  end

  def api_url
    "https://api.stormpath.com/vendors/github/events"
  end

end