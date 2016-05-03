class Service::Leanpub < Service::HttpPost
  string :api_key, :slug

  white_list :slug

  default_events :push

  url "https://leanpub.com"
  logo_url "https://leanpub.com/assets/leanpub_logo_small.png"

  maintained_by :github => 'spatten',
    :email => 'scott@leanpub.com',
    :twitter => '@scott_patten'

  supported_by :web => 'https://leanpub.com/contact',
    :email => 'hello@leanpub.com',
    :twitter => '@leanpub'

  def receive_event
    slug = required_config_value('slug')
    api_key = required_config_value('api_key')

    if api_key.match(/^[A-Za-z0-9_-]+$/) == nil
      raise_config_error "Invalid api key"
    end

    if slug.match(/^[A-Za-z0-9_-]+$/) == nil
      raise_config_error "Invalid slug"
    end

    url = "https://leanpub.com:443/#{slug}/preview?api_key=#{api_key}"
    deliver url
  end
end
