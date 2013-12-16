class Service::Landscape < Service::HttpPost
  default_events :push

  url "https://landscape.io"
  logo_url "https://landscape-io.s3.amazonaws.com/img/landscape_logo.png"

  maintained_by :github => 'landscapeio'

  supported_by :web => 'https://landscape.io/contact',
    :email => 'help@landscape.io',
    :twitter => 'landscapeio',
    :github  => 'landscapeio'

  def receive_event
    deliver 'https://landscape.io/hooks/github'
  end
end
