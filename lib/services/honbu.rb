class Service::Honbu < Service::HttpPost
  password :token


  default_events :push, :issues, :issue_comment, :commit_comment,
    :create, :delete, :pull_request, :follow, :gollum, :fork,
    :member, :team_add, :deployment, :deployment_status



  url "http://honbu.io"
  logo_url "http://honbu.io/assets/honbu-website-logo.png"

  maintained_by :github => 'RedFred7'

  supported_by :web => 'http://honbu.io/company',
    :email => 'support@honbu.io'

  def receive_event
    token = required_config_value('token')

    http.headers['Authorization'] = "#{token}"
    http.headers['X-GitHub-Event'] = event.to_s

    url = "https://integrations.honbu.io/github"

    deliver url
  end
end
