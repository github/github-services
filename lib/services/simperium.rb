class Service::Simperium < Service::HttpPost
  string :app_id, :token

  white_list :app_id

  default_events :push, :issues, :issue_comment, :commit_comment,
    :pull_request, :pull_request_review_comment, :watch, :fork,
    :fork_apply, :member, :public, :team_add, :status

  url "https://simperium.com"
  logo_url "https://simperium.com/media/images/simperium_logo_black_sm.png"

  maintained_by :github => 'fredrocious',
    :twitter => '@fredrocious'

  supported_by :web => 'https://simperium.com/contact',
    :email => 'help@simperium.com',
    :twitter => '@simperium'

  def receive_event
    appid = required_config_value('app_id')
    token = required_config_value('token')

    wrap_http_errors do
      url = set_url "https://api.simperium.com/1/#{appid}/#{event.to_s}/i/"
      http.headers['X-Simperium-Token'] = token

      body = encode_body
      http_post(url, body)
    end
  end
end

