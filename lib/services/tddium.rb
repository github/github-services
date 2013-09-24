class Service::Tddium < Service::HttpPost
  string :token
  string :override_url

  white_list :override_url

  url "https://www.tddium.com"
  logo_url "https://www.tddium.com/favicon.ico"

  maintained_by :github => 'solanolabs', :twitter => '@solanolabs'
  supported_by  :web => 'https://support.tddium.com/', :email => 'support@tddium.com'

  default_events Service::ALL_EVENTS

  def receive_event
    token = required_config_value('token')
    override_url = data['override_url']

    url_base = override_url.present? ? override_url : "https://hooks.tddium.com:443/1/github"
    tddium_url = "#{url_base}/#{token}" 
    deliver tddium_url
  end
end
