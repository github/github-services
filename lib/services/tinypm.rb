class Service::TinyPM < Service::HttpPost
  string :url
  # white_list :server

  default_events :push

  url "http://www.tinypm.com"
  logo_url "http://www.tinypm.com/images/tinypm_logo.gif"

  maintained_by :github => 'raho',
    :email => 'rafal.hotlos@gmail.com'

  supported_by :web => 'http://www.tinypm.com/',
    :email => 'support@tinypm.com'


  def receive_push
    server_url = required_config_value('url')
    http.headers['Content-Type'] = 'application/json'
    http_post(server_url, generate_json(payload))
  end

end
