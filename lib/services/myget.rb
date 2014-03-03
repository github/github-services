class Service::MyGet < Service::HttpPost
  string :hook_url

  white_list :hook_url

  url "https://www.myget.org"
  logo_url "https://www.myget.org/Content/images/myget/myget_125x25.png"
  
  default_events :push

  maintained_by :github => 'myget',
    :twitter => '@MyGetTeam'

  supported_by :web => 'https://www.myget.org/support',
    :email => 'support@myget.org',
    :twitter => '@MyGetTeam'

  def receive_event
    url = required_config_value('hook_url')
    
    deliver url
  end
end
