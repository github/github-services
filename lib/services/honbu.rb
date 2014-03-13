class Service::Honbu < Service::HttpPost
  string :token


  default_events :push, :issues, :issue_comment, :commit_comment,
    :create, :delete, :pull_request,  
    :gollum, :watch, :release, :fork, :member, :public, :team_add, 
    :status, :deployment, :deployment_status

  url "http://honbu.io"
  logo_url "http://honbu.io/assets/honbu-website-logo.png"

  maintained_by :github => 'RedFred7'

  supported_by :web => 'http://honbu.io/company',
    :email => 'support@honbu.io'

  def receive_event
    token = required_config_value('token')

    http.headers['Authorization'] = "#{token}"

    url = "https://integrations.honbu.io/github"

    deliver url
  end
end
