class Service::Sqwiggle < Service::HttpPost
  string :token, :room

  # only include 'room' in the debug logs, skip the api token.
  white_list :room

  default_events :push, :issues, :issue_comment, :commit_comment,
    :pull_request, :pull_request_review_comment, :watch, :fork,
    :fork_apply, :member, :public, :team_add, :status

  url "https://www.sqwiggle.com"
  logo_url "https://sqwiggle-assets.s3.amazonaws.com/assets/logo-header-b4bc3b6e82e42a0beb96b7fa413537f6.png"

  maintained_by :github => 'lukeroberts1990',
    :twitter => '@lukeroberts1990'

  supported_by :web => 'https://www.sqwiggle.com/help',
    :email => 'howdy@sqwiggle.com',
    :twitter => '@sqwiggle'

  def receive_event
    token = required_config_value('token')

    #TODO
    # if token.match(/^[A-Za-z0-9]+$/) == nil
    #   raise_config_error "Invalid token"
    # end
    
    http.basic_auth token, 'X'

    # url = "https://api.simperium.com:443/1/#{appid}/#{bucket}/i/#{delivery_guid}"
    url = "http://localhost:3001/integrations/github/#{room}"
    deliver url
  end
end
