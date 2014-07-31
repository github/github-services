class Service::Choir < Service::HttpPost
  string :api_key

  default_events :commit_comment, :create, :delete, :download, :follow, :fork,
      :fork_apply, :gollum, :issue_comment, :issues, :member, :public,
      :pull_request, :push, :team_add, :watch, :pull_request_review_comment,
      :status

  url "https://choir.io"
  logo_url "https://choir.io/static/images/logos/api.png"

  maintained_by :github => 'alexdong',
    :twitter => '@alexdong'

  supported_by :email => 'info@beachmonks.com',
    :twitter => '@beachmonks'

  def receive_event
    apikey = required_config_value('api_key')

    if apikey.match(/^[a-z0-9]{16}$/) == nil
      raise_config_error "Invalid api key"
    end

    url = "https://hooks.choir.io/#{apikey}/github"
    deliver url
  end
end
