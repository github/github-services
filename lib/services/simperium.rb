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
    appid = data['app_id'].to_s
    appid.gsub! /\s/, ''

    token = data['token'].to_s
    token.gsub! /\s/, ''

    if appid.empty?
      raise_config_error 'Invalid app id.'
    end

    if token.empty?
      raise_config_error 'Invalid token.'
    end

    wrap_http_errors do
      url = set_url "https://api.simperium.com/1/#{appid}/#{event.to_s}/i/"
      http.headers['X-Simperium-Token'] = token

      body = encode_body
      http_post(url, body)
    end
  end
end

