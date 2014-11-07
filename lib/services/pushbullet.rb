class Service::Pushbullet < Service::HttpPost
  string :api_key, :device_iden

  default_events :push, :issues, :pull_request

  url "https://www.pushbullet.com/"
  logo_url "https://www.pushbullet.com/img/header-logo.png"

  maintained_by :github => 'tuhoojabotti',
    :twitter => 'tuhoojabotti',
    :web => 'http://tuhoojabotti.com/#contact'

  supported_by :web => 'https://www.pushbullet.com/help',
    :email => 'hey@pushbullet.com'

  def receive_event
    unless required_config_value('api_key').match(/^[A-Za-z0-9]+$/)
      raise_config_error "Invalid api key."
    end
    unless config_value('device_iden').match(/^([A-Za-z0-9]+|)$/)
      raise_config_error "Invalid device iden."
    end

    deliver "https://webhook.pushbullet.com:443/github"
  end
end
