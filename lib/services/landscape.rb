class Service::Landscape < Service::HttpPost
  string :token

  default_events :push

  url "https://landscape.io"
  logo_url "https://landscape-io.s3.amazonaws.com/img/landscape_logo.png"

  maintained_by :github => 'landscapeio'

  supported_by :web => 'https://landscape.io/contact',
    :email => 'help@landscape.io',
    :twitter => 'landscapeio',
    :github  => 'landscapeio'

  def receive_event
    token = required_config_value('token')

    if token.match(/^[a-z0-9]{32}$/) == nil
      raise_config_error "Invalid token"
    end

    http.headers['Authorization'] = "Token #{token}"

    url = "https://landscape.io/hooks/github"
    deliver url
  end
end
