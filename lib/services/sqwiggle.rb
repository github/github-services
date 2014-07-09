class Service::Sqwiggle < Service::HttpPost
  password :token
  string :room

  # only include 'room' in the debug logs, skip the api token.
  white_list :room

  #accept all events and filter on sqwiggle servers so we can add events as
  #requested without the need to wait on Github PR's
  default_events Service::ALL_EVENTS

  url "https://www.sqwiggle.com"
  logo_url "https://sqwiggle-assets.s3.amazonaws.com/assets/logo-header-b4bc3b6e82e42a0beb96b7fa413537f6.png"

  maintained_by :github => 'lukeroberts1990',
    :twitter => '@lukeroberts1990'

  supported_by :web => 'https://www.sqwiggle.com/help',
    :email => 'howdy@sqwiggle.com',
    :twitter => '@sqwiggle'

  def receive_event
    token = required_config_value('token')
    http.basic_auth token, 'X'

    #dev url
    # url = "http://localhost:3001/integrations/github/#{data['room']}"

    #production url
    url = "https://api.sqwiggle.com:443/integrations/github/#{data['room']}"

    deliver url
  end
end
